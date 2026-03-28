//
//  PlaybackFile.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  音声ファイルのドメインモデル

import Foundation

/// 音声ファイルを表すドメインモデル
struct PlaybackFile: Identifiable, Equatable {
    /// URL から安定的に導出するID（fetchAll() を複数回呼んでも同じファイルは同じIDを持つ）
    var id: URL { url }
    let url: URL
    let fileName: String  // 例: "2026-02-26_21-30-00.m4a"
    let createdAt: Date
    let duration: TimeInterval
    let fileSize: Int64
}
