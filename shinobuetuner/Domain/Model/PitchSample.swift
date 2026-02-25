//
//  PitchSample.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  ピッチ検出結果を表すモデル

import Foundation

/// ピッチ検出結果（時刻と周波数のペア）
struct PitchSample {
    let time: TimeInterval   // セッション開始からの経過時間（秒）
    let frequency: Float     // 周波数（Hz）
}
