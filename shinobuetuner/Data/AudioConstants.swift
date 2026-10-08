//
//  AudioConstants.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/03/28.
//
//  音声処理で使用する共有定数

/// 音声処理で使用する共有定数
enum AudioConstants {
    /// 無音と判定する閾値
    /// - MicrophoneDataSource: vDSP_rmsqv で計算した RMS と比較
    /// - PlaybackFileRepositoryImpl: サンプルの絶対値（ピーク）と比較
    static let noiseThreshold: Float = 0.003

    /// ピッチ検出の上限周波数（Hz）
    /// 八本調子の大甲 4'（F7 = 約2807Hz）をカバーする（六本調子の 4' は E♭7 = 約2500Hz）
    static let maxDetectableFrequency: Float = 3000.0

    /// アンサンブル安定性判定に使うリングバッファのフレーム数
    static let ensembleBufferSize: Int = 30
}
