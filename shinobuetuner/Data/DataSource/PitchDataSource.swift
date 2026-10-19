//
//  PitchDataSource.swift
//  shinobuetuner
//
//  ピッチ検出の入力元（マイク / テスト用音声ファイル）を差し替えるためのプロトコル

import Combine
import Foundation

/// 音声を取り込んでピッチを検出するデータソースのプロトコル
protocol PitchDataSource {
    /// 検出したピッチ（Hz）をemitするパブリッシャー（0は無音）
    var publisher: AnyPublisher<Float, Never> { get }

    /// スペクトル情報付きパブリッシャー（アンサンブルモニタリング用）
    var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> { get }

    /// マイクのアクセス許可を要求する
    /// - Returns: 許可されたかどうか
    func requestPermission() async -> Bool

    /// 音声キャプチャを開始する
    func startCapture()

    /// 音声キャプチャを停止する
    func stopCapture()

    /// 録音を開始する（startCapture() の後に呼ぶ）
    /// - Parameter url: 保存先URL（.m4a）
    func startRecording(to url: URL) throws

    /// 録音を停止してファイルを閉じる
    func stopRecording()
}
