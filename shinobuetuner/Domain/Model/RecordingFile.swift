//
//  RecordingFile.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  録音ファイルのドメインモデル

import Foundation

/// 録音ファイルを表すドメインモデル
struct RecordingFile: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let fileName: String  // 例: "2026-02-26_21-30-00.m4a"
    let createdAt: Date
    let duration: TimeInterval
    let fileSize: Int64
}
