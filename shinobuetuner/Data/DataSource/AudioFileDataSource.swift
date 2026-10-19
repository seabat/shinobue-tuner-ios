//
//  AudioFileDataSource.swift
//  shinobuetuner
//
//  テスト用：マイクの代わりに音声ファイルをループ再生してピッチを検出するデータソース（Debug ビルドのみ）
//  起動引数 `-UITestAudioFile <ファイル名>` を渡すと、PitchRepositoryImpl がマイクの代わりにこれを使う
//  ファイルはアプリのデータコンテナの Library/UITestAudio/ に置く（.claude/skills/ios-ui-operator/recipe.md 参照）

#if DEBUG
import Foundation
import Combine
import AVFoundation

/// 音声ファイルを入力としてピッチを検出するデータソース（UI テスト用）
final class AudioFileDataSource: PitchDataSource {
    /// 起動引数でテスト用音声ファイルを指定するキー
    static let launchArgumentKey = "UITestAudioFile"

    /// 検出したピッチとHPSスペクトルをセットでemitするSubject（pitch=0は無音）
    private let subject = PassthroughSubject<(pitch: Float, magnitudes: [Float]), Never>()

    var publisher: AnyPublisher<Float, Never> {
        subject.map { $0.pitch }.eraseToAnyPublisher()
    }

    var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> {
        let binWidth = Float(fileFormat.sampleRate) / Float(fftSize)
        return subject
            .map { (pitch: $0.pitch, magnitudes: $0.magnitudes, binWidth: binWidth) }
            .eraseToAnyPublisher()
    }

    private let fileURL: URL
    private let fileFormat: AVAudioFormat
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let fftSize = 4096

    /// 録音中に書き込むファイル（nonisolated(unsafe) でバックグラウンドスレッドからアクセス）
    nonisolated(unsafe) private var recordingFile: AVAudioFile? = nil

    /// - Parameter fileURL: 入力にする音声ファイル
    init(fileURL: URL) throws {
        self.fileURL = fileURL
        self.fileFormat = try AVAudioFile(forReading: fileURL).processingFormat
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: fileFormat)
        // テスト中にスピーカーから音が出ないようにする（タップは playerNode の出力から取るので検出には影響しない）
        engine.mainMixerNode.outputVolume = 0
    }

    /// 起動引数でファイルが指定されていればデータソースを生成する。指定がない・読めない場合は nil
    static func fromLaunchArguments() -> AudioFileDataSource? {
        guard let fileName = UserDefaults.standard.string(forKey: launchArgumentKey) else { return nil }
        let url = URL.libraryDirectory.appending(path: "UITestAudio").appending(path: fileName)
        do {
            return try AudioFileDataSource(fileURL: url)
        } catch {
            print("テスト用音声ファイルを開けません: \(url.path) \(error)")
            return nil
        }
    }

    /// テスト用なのでマイク権限の問い合わせはそのまま行う（権限を許可した状態でテストする）
    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    /// 音声ファイルのループ再生とピッチ検出を開始する
    func startCapture() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        let buffer: AVAudioPCMBuffer
        do {
            let file = try AVAudioFile(forReading: fileURL)
            guard let pcm = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return }
            try file.read(into: pcm)
            buffer = pcm
        } catch {
            print("テスト用音声ファイルの読み込みエラー: \(error)")
            return
        }

        let sampleRate = Float(fileFormat.sampleRate)
        let fftSize = fftSize
        playerNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fftSize), format: fileFormat) { [weak self] buffer, _ in
            guard let self else { return }

            if let file = self.recordingFile {
                try? file.write(from: buffer)
            }

            // ピッチ検出は本番（マイク入力）と同じ処理を使う
            let result = MicrophoneDataSource.detectPitchWithSpectrum(
                buffer: buffer,
                sampleRate: sampleRate,
                fftSize: fftSize
            )

            Task { @MainActor [weak self] in
                self?.subject.send((pitch: result.pitch, magnitudes: result.magnitudes))
            }
        }

        do {
            try engine.start()
        } catch {
            print("AudioEngine起動エラー: \(error)")
            return
        }
        // 先頭から繰り返し再生する（UI テストで表示を取りこぼしても次の周回で確認できるように）
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
        playerNode.play()
    }

    /// 再生とピッチ検出を停止する
    func stopCapture() {
        playerNode.stop()
        playerNode.removeTap(onBus: 0)
        engine.stop()

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }

    /// 録音を開始する（startCapture() の後に呼ぶ）
    func startRecording(to url: URL) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: fileFormat.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recordingFile = try AVAudioFile(forWriting: url, settings: settings)
    }

    /// 録音を停止してファイルを閉じる
    func stopRecording() {
        recordingFile = nil
    }
}
#endif
