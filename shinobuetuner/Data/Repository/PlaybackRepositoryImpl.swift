//
//  PlaybackRepositoryImpl.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  PlaybackRepository の具体実装（AudioPlayerDataSource に委譲）

import Combine
import Foundation

/// PlaybackRepository の具体実装
final class PlaybackRepositoryImpl: PlaybackRepository {
    private let dataSource: AudioPlayerDataSource

    init(dataSource: AudioPlayerDataSource = AudioPlayerDataSource()) {
        self.dataSource = dataSource
    }

    var playbackTimePublisher: AnyPublisher<TimeInterval, Never> {
        dataSource.playbackTimePublisher
    }

    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        dataSource.isPlayingPublisher
    }

    func play(url: URL) throws {
        try dataSource.play(url: url)
    }

    func pause() {
        dataSource.pause()
    }

    func resume() {
        dataSource.resume()
    }

    func stop() {
        dataSource.stop()
    }
}
