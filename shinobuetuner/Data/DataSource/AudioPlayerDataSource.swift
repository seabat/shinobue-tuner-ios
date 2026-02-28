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
        guard let file = audioFile else { return }

        if !engine.isRunning {
            try? engine.start()
        }

        let sampleRate = file.processingFormat.sampleRate
        let totalFrames = file.length
        let targetFrame = AVAudioFramePosition(max(0, min(seekOffset * sampleRate, Double(totalFrames - 1))))
        let remainingFrames = AVAudioFrameCount(totalFrames - targetFrame)

        guard remainingFrames > 0 else { return }

        let totalDuration = Double(totalFrames) / sampleRate

        // sessionID を更新して古い completion callback を無効化する
        let currentSessionID = UUID()
        sessionID = currentSessionID

        // seekOffset から確実に再スケジュールして再生する
        // （pause() 後の resume や seek 後の resume のどちらにも対応）
        playerNode.stop()
        playerNode.scheduleSegment(
            file,
            startingFrame: targetFrame,
            frameCount: remainingFrames,
            at: nil,
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
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

    /// 指定した位置（秒）にシークして再生を継続する
    func seek(to time: TimeInterval) {
        guard let file = audioFile else { return }

        let sampleRate = file.processingFormat.sampleRate
        let totalFrames = file.length
        let targetFrame = AVAudioFramePosition(max(0, min(time * sampleRate, Double(totalFrames - 1))))
        let remainingFrames = AVAudioFrameCount(totalFrames - targetFrame)

        let wasPlaying = isPlayingSubject.value

        // sessionID を先に更新して既存の completion callback を無効化する
        let currentSessionID = UUID()
        sessionID = currentSessionID

        // スケジュール済みバッファをクリア（engine は止めない）
        playerNode.stop()
        stopTimeTracking()

        // 新しい再生位置を保存
        seekOffset = Double(targetFrame) / sampleRate
        timeSubject.send(seekOffset)

        guard remainingFrames > 0 else { return }

        // 再生中だった場合のみ即座に再スケジュールして再生を継続する
        // 一時停止中の場合は seekOffset のみ更新し、resume() でスケジュールと再生を行う
        if wasPlaying {
            let totalDuration = Double(totalFrames) / sampleRate

            playerNode.scheduleSegment(
                file,
                startingFrame: targetFrame,
                frameCount: remainingFrames,
                at: nil,
                completionCallbackType: .dataPlayedBack
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
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
