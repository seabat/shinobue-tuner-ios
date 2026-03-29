//
//  PlaybackSettings.swift
//  shinobuetuner
//
//  音声ファイル再生に関する設定値を保持するデータクラス

import Foundation

/// プレイリストの並び替え条件
enum PlaybackSortOrder: String, CaseIterable {
    case createdAtDescending = "createdAtDescending"
    case createdAtAscending  = "createdAtAscending"
    case fileNameDescending  = "fileNameDescending"
    case fileNameAscending   = "fileNameAscending"

    var displayName: String {
        switch self {
        case .createdAtDescending: return "作成日時（新しい順）"
        case .createdAtAscending:  return "作成日時（古い順）"
        case .fileNameDescending:  return "ファイル名（Z → A）"
        case .fileNameAscending:   return "ファイル名（A → Z）"
        }
    }
}

/// 音声ファイル再生に関する設定値
struct PlaybackSettings {
    /// 頭出し判定に使う無音ピーク振幅のしきい値（デフォルト: 0.003）
    var trimNoisePeakThreshold: Float = 0.003
    /// プレイリストの並び替え条件（デフォルト: 作成日時の降順）
    var sortOrder: PlaybackSortOrder = .createdAtDescending
}
