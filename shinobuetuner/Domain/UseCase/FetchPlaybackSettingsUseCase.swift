//
//  FetchPlaybackSettingsUseCase.swift
//  shinobuetuner
//
//  音声ファイル再生設定取得ユースケース

import Foundation

/// 音声ファイル再生設定を取得するユースケースのプロトコル
protocol FetchPlaybackSettingsUseCaseProtocol {
    func callAsFunction() -> PlaybackSettings
}

/// 音声ファイル再生設定を取得するユースケースの具体実装
final class FetchPlaybackSettingsUseCase: FetchPlaybackSettingsUseCaseProtocol {
    private let repository: any PlaybackSettingsRepository

    init(repository: any PlaybackSettingsRepository) {
        self.repository = repository
    }

    func callAsFunction() -> PlaybackSettings {
        repository.fetch()
    }
}
