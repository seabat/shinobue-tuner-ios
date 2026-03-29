//
//  TunerSettingsRepository.swift
//  shinobuetuner
//
//  チューナー設定のリポジトリプロトコル

import Foundation

/// チューナー設定を永続化するリポジトリのプロトコル
protocol TunerSettingsRepository {
    /// 保存済みの設定値を取得する
    func fetch() -> TunerSettings

    /// 設定値を保存する
    func save(_ settings: TunerSettings)
}
