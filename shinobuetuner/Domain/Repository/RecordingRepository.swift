//
//  RecordingRepository.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  録音ファイルの保存・取得・削除リポジトリのプロトコル定義

import Foundation

/// 録音ファイルを管理するリポジトリのプロトコル
protocol RecordingRepository {
    /// 保存済み録音ファイルの一覧を新しい順に返す
    func fetchAll() -> [RecordingFile]

    /// 指定URLの録音ファイルを削除する
    func delete(url: URL) throws

    /// 新しい録音の保存先URLを生成して返す（ファイル名: "yyyy-MM-dd_HH-mm-ss.m4a"）
    func newRecordingURL() -> URL
}
