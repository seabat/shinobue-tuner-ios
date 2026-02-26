//
//  PitchRepository.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  ピッチデータを提供するリポジトリのプロトコル定義

import Combine
import Foundation

/// ピッチデータを提供するリポジトリのプロトコル
protocol PitchRepository {
    /// 検出したピッチ（Hz）をemitするパブリッシャー（0は無音）
    var pitchPublisher: AnyPublisher<Float, Never> { get }

    /// マイクの監視を開始する
    func startMonitoring()

    /// マイクの監視を停止する
    func stopMonitoring()

    /// マイクのアクセス許可を要求する
    /// - Returns: 許可されたかどうか
    func requestPermission() async -> Bool

    /// 録音を開始する（startMonitoring() の後に呼ぶ）
    /// - Parameter url: 保存先URL
    func startRecording(to url: URL) throws

    /// 録音を停止してファイルを閉じる
    func stopRecording()
}
