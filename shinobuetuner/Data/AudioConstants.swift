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
}
