//
//  AudioPlayerDataSource.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  AVAudioEngine + AVAudioPlayerNode を使った音声ファイル再生

import AVFoundation
import Combine

/// 音声ファイルを再生するデータソース
final class AudioPlayerDataSource {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    private let timeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let isPlayingSubject = CurrentValueSubject<Bool, Never>(false)

    private var audioFile: AVAudioFile?
    /// play() / resume() 時の開始日時（経過時間の計算基点）
    private var playStartTime: Date? = nil
    /// pause() 時に保存する再生位置（resume() 後の基点）
    private var seekOffset: TimeInterval = 0
    /// 再生セッションID（stop() のたびに更新し、古いコールバックを無効化する）
    private var sessionID = UUID()
    private var timerCancellable: AnyCancellable?

    var playbackTimePublisher: AnyPublisher<TimeInterval, Never> {
        timeSubject.eraseToAnyPublisher()
    }

    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        isPlayingSubject.eraseToAnyPublisher()
    }

    init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
    }

    /// 指定URLの音声ファイルを再生する
    func play(url: URL) throws {
        stop()

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        #endif

        let file = try AVAudioFile(forReading: url)
        audioFile = file
        seekOffset = 0

        let totalDuration = Double(file.length) / file.processingFormat.sampleRate

        // 新しいセッションIDを発行（stop() 前のコールバックを無効化するため）
        let currentSessionID = UUID()
        sessionID = currentSessionID

        engine.connect(playerNode, to: engine.mainMixerNode, format: file.processingFormat)
        try engine.start()

        // .dataPlayedBack: 音がスピーカーから出終わった後に呼ばれる
        // （デフォルトの completionHandler はバッファ書き込み完了時に呼ばれるため早すぎる）
        playerNode.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor [weak self] in
                // セッションIDが変わっていれば別ファイルに切り替わっているためスキップ
                guard let self, self.sessionID == currentSessionID else { return }
                self.timeSubject.send(totalDuration)
                self.isPlayingSubject.send(false)
                self.stopTimeTracking()
            }
        }
        playerNode.play()
        playStartTime = Date()
        isPlayingSubject.send(true)
        startTimeTracking()
    }

    /// 再生を一時停止する
    func pause() {
        seekOffset = currentPlaybackTime()
        playStartTime = nil
        playerNode.pause()
        isPlayingSubject.send(false)
        stopTimeTracking()
    }

    /// 一時停止した再生を再開する
    func resume() {
        playerNode.play()
        playStartTime = Date()
        isPlayingSubject.send(true)
        startTimeTracking()
    }

    /// 再生を停止してリソースを解放する
    func stop() {
        // sessionID を更新して前のコールバックを無効化する
        sessionID = UUID()
        stopTimeTracking()
        playerNode.stop()
        if engine.isRunning { engine.stop() }
        audioFile = nil
        seekOffset = 0
        playStartTime = nil
        isPlayingSubject.send(false)
        timeSubject.send(0)

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }

    // MARK: - 内部処理

    /// 0.1秒ごとに再生位置を更新するタイマーを開始する
    private func startTimeTracking() {
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                timeSubject.send(currentPlaybackTime())
            }
    }

    private func stopTimeTracking() {
        timerCancellable = nil
    }

    /// 現在の再生位置（秒）を返す
    /// sampleTime は engine.stop() → start() をまたいでリセットされないため、
    /// Date ベースの経過時間で計算する
    private func currentPlaybackTime() -> TimeInterval {
        guard let startTime = playStartTime else {
            return seekOffset
        }
        return seekOffset + Date().timeIntervalSince(startTime)
    }
}
