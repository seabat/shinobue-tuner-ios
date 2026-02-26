//
//  MonitorPitchUseCase.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  ピッチ監視のユースケース（Protocol + 具体実装）

import Combine
import Foundation

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

    /// 録音を開始する（start() の後に呼ぶ）
    func startRecording(to url: URL) throws

    /// 録音を停止する
    func stopRecording()
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

    func startRecording(to url: URL) throws {
        try repository.startRecording(to: url)
    }

    func stopRecording() {
        repository.stopRecording()
    }
}
