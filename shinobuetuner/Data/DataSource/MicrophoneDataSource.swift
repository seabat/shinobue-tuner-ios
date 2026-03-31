//
//  MicrophoneDataSource.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  AVAudioEngineとFFT/HPSを使ったマイクからのリアルタイムピッチ検出

import Foundation
import Combine
import AVFoundation
import Accelerate

/// マイク音声からリアルタイムにピッチを検出するデータソース
final class MicrophoneDataSource {
    /// 検出したピッチとHPSスペクトルをセットでemitするSubject（pitch=0は無音）
    private let subject = PassthroughSubject<(pitch: Float, magnitudes: [Float]), Never>()

    /// 外部公開用パブリッシャー（後方互換：ピッチのみ）
    var publisher: AnyPublisher<Float, Never> {
        subject.map { $0.pitch }.eraseToAnyPublisher()
    }

    /// スペクトル情報付きパブリッシャー（アンサンブルモニタリング用）
    var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> {
        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        let binWidth = Float(inputFormat.sampleRate) / Float(4096)
        return subject
            .map { (pitch: $0.pitch, magnitudes: $0.magnitudes, binWidth: binWidth) }
            .eraseToAnyPublisher()
    }

    private let engine = AVAudioEngine()
    private var sessionStartTime: Date = Date()

    /// 録音中に書き込むファイル（nonisolated(unsafe) でバックグラウンドスレッドからアクセス）
    nonisolated(unsafe) private var recordingFile: AVAudioFile? = nil

    /// マイクのアクセス許可を要求する
    /// - Returns: 許可されたかどうか
    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    /// マイクの音声キャプチャを開始する
    func startCapture() {
        // AVAudioSessionの設定（iOS）
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            print("AVAudioSession設定エラー: \(error)")
            return
        }
        #endif

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        let sampleRate = Float(inputFormat.sampleRate)
        let fftSize = 4096

        sessionStartTime = Date()

        // 音声タップを設置してバッファを受け取る
        inputNode.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(fftSize),
            format: inputFormat
        ) { [weak self] buffer, _ in
            guard let self else { return }

            // 録音中はバッファをファイルに書き込む（バックグラウンドスレッドで安全）
            if let file = self.recordingFile {
                try? file.write(from: buffer)
            }

            // ピッチ検出（バックグラウンドスレッドで実行可能）
            let result = MicrophoneDataSource.detectPitchWithSpectrum(
                buffer: buffer,
                sampleRate: sampleRate,
                fftSize: fftSize
            )

            // subject.send をメインスレッドで呼び出す
            Task { @MainActor [weak self] in
                self?.subject.send((pitch: result.pitch, magnitudes: result.magnitudes))
            }
        }

        do {
            try engine.start()
        } catch {
            print("AudioEngine起動エラー: \(error)")
        }
    }

    /// マイクの音声キャプチャを停止する
    func stopCapture() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }

    /// 録音を開始する（startCapture() の後に呼ぶ）
    /// - Parameter url: 保存先URL（.m4a）
    func startRecording(to url: URL) throws {
        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recordingFile = try AVAudioFile(forWriting: url, settings: settings)
    }

    /// 録音を停止してファイルを閉じる
    func stopRecording() {
        recordingFile = nil  // nilにするとAVAudioFileが閉じられる
    }

    // MARK: - ピッチ検出（静的メソッド・スレッドセーフ）

    /// FFT + HPSアルゴリズムによるピッチ検出（スペクトル情報付き）
    /// - Parameters:
    ///   - buffer: 音声バッファ
    ///   - sampleRate: サンプルレート（Hz）
    ///   - fftSize: FFTサイズ（2の累乗）
    /// - Returns: (pitch: 検出周波数Hz, magnitudes: HPSスペクトル)、無音時は pitch=0
    nonisolated static func detectPitchWithSpectrum(
        buffer: AVAudioPCMBuffer,
        sampleRate: Float,
        fftSize: Int
    ) -> (pitch: Float, magnitudes: [Float]) {
        guard let channelData = buffer.floatChannelData?[0] else { return (0, []) }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return (0, []) }

        let halfSize = fftSize / 2
        let log2n = vDSP_Length(log2f(Float(fftSize)))

        var signal = [Float](repeating: 0, count: fftSize)
        let copyCount = min(frameLength, fftSize)
        for i in 0..<copyCount {
            signal[i] = channelData[i]
        }

        var rms: Float = 0
        vDSP_rmsqv(signal, 1, &rms, vDSP_Length(copyCount))
        guard rms > AudioConstants.noiseThreshold else { return (0, []) }

        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(signal, 1, window, 1, &signal, 1, vDSP_Length(fftSize))

        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return (0, []) }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        var realParts = [Float](repeating: 0, count: halfSize)
        var imagParts = [Float](repeating: 0, count: halfSize)
        var magnitudes = [Float](repeating: 0, count: halfSize)

        signal.withUnsafeBytes { rawPtr in
            let complexPtr = rawPtr.baseAddress!.assumingMemoryBound(to: DSPComplex.self)
            realParts.withUnsafeMutableBufferPointer { realBuf in
                imagParts.withUnsafeMutableBufferPointer { imagBuf in
                    var split = DSPSplitComplex(
                        realp: realBuf.baseAddress!,
                        imagp: imagBuf.baseAddress!
                    )
                    vDSP_ctoz(complexPtr, 2, &split, 1, vDSP_Length(halfSize))
                    vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                    vDSP_zvmags(&split, 1, &magnitudes, 1, vDSP_Length(halfSize))
                }
            }
        }

        var hpsSpectrum = magnitudes
        let numHarmonics = 3
        let hpsMaxBin = halfSize / numHarmonics
        for harmonic in 2...numHarmonics {
            for i in 0..<hpsMaxBin {
                hpsSpectrum[i] *= magnitudes[i * harmonic]
            }
        }

        let binWidth = sampleRate / Float(fftSize)
        let minBin = max(1, Int(100.0 / binWidth))
        let maxBin = min(Int(2600.0 / binWidth), hpsMaxBin - 2)
        guard minBin < maxBin else { return (0, hpsSpectrum) }

        var maxMag: Float = 0
        var peakBin = minBin
        for i in minBin...maxBin {
            if hpsSpectrum[i] > maxMag {
                maxMag = hpsSpectrum[i]
                peakBin = i
            }
        }

        var avgMag: Float = 0
        vDSP_meanv(hpsSpectrum, 1, &avgMag, vDSP_Length(hpsMaxBin))
        guard maxMag > avgMag * 8 else { return (0, hpsSpectrum) }

        guard peakBin > 0 && peakBin < hpsMaxBin - 1 else {
            return (Float(peakBin) * binWidth, hpsSpectrum)
        }
        let alpha = hpsSpectrum[peakBin - 1]
        let beta  = hpsSpectrum[peakBin]
        let gamma = hpsSpectrum[peakBin + 1]
        let denominator = alpha - 2 * beta + gamma
        let offset: Float = abs(denominator) > 1e-6 ? 0.5 * (alpha - gamma) / denominator : 0

        return ((Float(peakBin) + offset) * binWidth, hpsSpectrum)
    }

    /// FFT + HPSアルゴリズムによるピッチ検出
    /// - Parameters:
    ///   - buffer: 音声バッファ
    ///   - sampleRate: サンプルレート（Hz）
    ///   - fftSize: FFTサイズ（2の累乗）
    /// - Returns: 検出されたピッチ周波数（Hz）、無音時は0
    nonisolated static func detectPitch(buffer: AVAudioPCMBuffer, sampleRate: Float, fftSize: Int) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        let halfSize = fftSize / 2
        let log2n = vDSP_Length(log2f(Float(fftSize)))

        // 信号をコピー（不足分はゼロパディング）
        var signal = [Float](repeating: 0, count: fftSize)
        let copyCount = min(frameLength, fftSize)
        for i in 0..<copyCount {
            signal[i] = channelData[i]
        }

        // RMSでノイズレベルチェック（無音は0を返す）
        var rms: Float = 0
        vDSP_rmsqv(signal, 1, &rms, vDSP_Length(copyCount))
        guard rms > AudioConstants.noiseThreshold else { return 0 }

        // ハン窓を適用してスペクトル漏れを軽減
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(signal, 1, window, 1, &signal, 1, vDSP_Length(fftSize))

        // FFTセットアップ
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return 0 }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        // 実数信号をDSPSplitComplexに変換してFFT実行
        var realParts = [Float](repeating: 0, count: halfSize)
        var imagParts = [Float](repeating: 0, count: halfSize)
        var magnitudes = [Float](repeating: 0, count: halfSize)

        signal.withUnsafeBytes { rawPtr in
            let complexPtr = rawPtr.baseAddress!.assumingMemoryBound(to: DSPComplex.self)
            realParts.withUnsafeMutableBufferPointer { realBuf in
                imagParts.withUnsafeMutableBufferPointer { imagBuf in
                    var split = DSPSplitComplex(
                        realp: realBuf.baseAddress!,
                        imagp: imagBuf.baseAddress!
                    )
                    // 実数信号を複素数形式に変換
                    vDSP_ctoz(complexPtr, 2, &split, 1, vDSP_Length(halfSize))
                    // 高速フーリエ変換
                    vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                    // 振幅スペクトルを計算
                    vDSP_zvmags(&split, 1, &magnitudes, 1, vDSP_Length(halfSize))
                }
            }
        }

        // HPS（倍音積スペクトル法）で基音を強調
        // 篠笛の倍音成分が強い場合でも基音を正確に検出できる
        var hpsSpectrum = magnitudes
        let numHarmonics = 3
        let hpsMaxBin = halfSize / numHarmonics
        for harmonic in 2...numHarmonics {
            for i in 0..<hpsMaxBin {
                hpsSpectrum[i] *= magnitudes[i * harmonic]
            }
        }

        // 篠笛の有効音域: 100Hz ～ 2600Hz（大甲音域のファ/Eb7=2500Hzをカバー）
        let binWidth = sampleRate / Float(fftSize)
        let minBin = max(1, Int(100.0 / binWidth))
        let maxBin = min(Int(2600.0 / binWidth), hpsMaxBin - 2)
        guard minBin < maxBin else { return 0 }

        // HPSスペクトルのピーク（最大値）を探す
        var maxMag: Float = 0
        var peakBin = minBin
        for i in minBin...maxBin {
            if hpsSpectrum[i] > maxMag {
                maxMag = hpsSpectrum[i]
                peakBin = i
            }
        }

        // 平均値との比較でノイズ判定
        var avgMag: Float = 0
        vDSP_meanv(hpsSpectrum, 1, &avgMag, vDSP_Length(hpsMaxBin))
        guard maxMag > avgMag * 8 else { return 0 }

        // 放物線補間でサブビン精度の周波数を計算
        guard peakBin > 0 && peakBin < hpsMaxBin - 1 else {
            return Float(peakBin) * binWidth
        }
        let alpha = hpsSpectrum[peakBin - 1]
        let beta  = hpsSpectrum[peakBin]
        let gamma = hpsSpectrum[peakBin + 1]
        let denominator = alpha - 2 * beta + gamma
        let offset: Float = abs(denominator) > 1e-6 ? 0.5 * (alpha - gamma) / denominator : 0

        return (Float(peakBin) + offset) * binWidth
    }
}
