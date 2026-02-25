//
//  PitchRepositoryImpl.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  PitchRepository プロトコルの具体実装（MicrophoneDataSource に委譲）

import Combine

/// PitchRepository の具体実装
final class PitchRepositoryImpl: PitchRepository {
    private let dataSource: MicrophoneDataSource

    init(dataSource: MicrophoneDataSource = MicrophoneDataSource()) {
        self.dataSource = dataSource
    }

    var pitchPublisher: AnyPublisher<Float, Never> {
        dataSource.publisher
    }

    func startMonitoring() {
        dataSource.startCapture()
    }

    func stopMonitoring() {
        dataSource.stopCapture()
    }

    func requestPermission() async -> Bool {
        await dataSource.requestPermission()
    }
}
