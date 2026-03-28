//
//  PlaybackFileRepository.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  音声ファイルの保存・取得・削除リポジトリのプロトコル定義

import Foundation

/// 音声ファイルを管理するリポジトリのプロトコル
protocol PlaybackFileRepository {
    /// 保存済み音声ファイルの一覧を新しい順に返す
    func fetchAll() -> [PlaybackFile]

    /// 指定URLの音声ファイルを削除する
    func delete(url: URL) throws

    /// 音声ファイルの名前を変更する（拡張子 .m4a は維持）。新しいURLを返す
    func rename(url: URL, newName: String) throws -> URL

    /// 新しい音声の保存先URLを生成して返す（ファイル名: "yyyy-MM-dd_HH-mm-ss.m4a"）
    func newPlaybackFileURL() -> URL

    /// 指定URLの音声ファイルから先頭の無音区間を除去し、新しいファイルを作成して返す
    func trimLeadingSilence(url: URL, threshold: Float) async throws -> URL
}
