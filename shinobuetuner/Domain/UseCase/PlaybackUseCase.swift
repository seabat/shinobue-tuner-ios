//
//  PlaybackUseCase.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  音声再生ユースケース（Protocol + 具体実装）

import Combine
import Foundation

/// 音声再生ユースケースのプロトコル
protocol PlaybackUseCaseProtocol {
    /// 現在の再生位置（秒）をemitするパブリッシャー
    var playbackTimePublisher: AnyPublisher<TimeInterval, Never> { get }

    /// 再生中かどうかをemitするパブリッシャー
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }

    /// 録音ファイルを再生する
    func play(recording: RecordingFile) throws

    /// 再生を一時停止する
    func pause()

    /// 一時停止した再生を再開する
    func resume()

    /// 再生を停止する
    func stop()
}

/// 音声再生ユースケースの具体実装
final class PlaybackUseCase: PlaybackUseCaseProtocol {
    private let repository: any PlaybackRepository

    init(repository: any PlaybackRepository) {
        self.repository = repository
    }

    var playbackTimePublisher: AnyPublisher<TimeInterval, Never> {
        repository.playbackTimePublisher
    }

    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        repository.isPlayingPublisher
    }

    func play(recording: RecordingFile) throws {
        try repository.play(url: recording.url)
    }

    func pause() {
        repository.pause()
    }

    func resume() {
        repository.resume()
    }

    func stop() {
        repository.stop()
    }
}
