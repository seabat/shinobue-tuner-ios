//
//  PlaybackSettings.swift
//  shinobuetuner
//
//  音声ファイル再生に関する設定値を保持するデータクラス

import Foundation

/// 音声ファイル再生に関する設定値
struct PlaybackSettings {
    /// 頭出し判定に使う無音ピーク振幅のしきい値（デフォルト: 0.003）
    var trimNoisePeakThreshold: Float = 0.003
}
