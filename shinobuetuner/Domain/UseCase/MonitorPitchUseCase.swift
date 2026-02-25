//
//  MonitorPitchUseCase.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  ピッチ監視のユースケース（Protocol + 具体実装）

import Combine

/// ピッチ監視ユースケースのプロトコル（ViewModel が依存するインターフェース）
protocol MonitorPitchUseCaseProtocol {
    /// 検出したピッチ（Hz）をemitするパブリッシャー（0は無音）
    var pitchPublisher: AnyPublisher<Float, Never> { get }

    /// ピッチ監視を開始する
    func start()

    /// ピッチ監視を停止する
    func stop()

    /// マイクのアクセス許可を要求する
    /// - Returns: 許可されたかどうか
    func requestPermission() async -> Bool
}

/// ピッチ監視ユースケースの具体実装
final class MonitorPitchUseCase: MonitorPitchUseCaseProtocol {
    private let repository: any PitchRepository

    init(repository: any PitchRepository) {
        self.repository = repository
    }

    var pitchPublisher: AnyPublisher<Float, Never> {
        repository.pitchPublisher
    }

    func start() {
        repository.startMonitoring()
    }

    func stop() {
        repository.stopMonitoring()
    }

    func requestPermission() async -> Bool {
        await repository.requestPermission()
    }
}
