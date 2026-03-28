//
//  PlaybackSettingsRepository.swift
//  shinobuetuner
//
//  音声ファイル設定のリポジトリプロトコル

import Foundation

/// 音声ファイル再生設定を永続化するリポジトリのプロトコル
protocol PlaybackSettingsRepository {
    /// 保存済みの設定値を取得する
    func fetch() -> PlaybackSettings

    /// 設定値を保存する
    func save(_ settings: PlaybackSettings)
}
