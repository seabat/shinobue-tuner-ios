//
//  SavePlaybackSettingsUseCase.swift
//  shinobuetuner
//
//  音声ファイル再生設定保存ユースケース

import Foundation

/// 音声ファイル再生設定を保存するユースケースのプロトコル
protocol SavePlaybackSettingsUseCaseProtocol {
    func callAsFunction(_ settings: PlaybackSettings)
}

/// 音声ファイル再生設定を保存するユースケースの具体実装
final class SavePlaybackSettingsUseCase: SavePlaybackSettingsUseCaseProtocol {
    private let repository: any PlaybackSettingsRepository

    init(repository: any PlaybackSettingsRepository) {
        self.repository = repository
    }

    func callAsFunction(_ settings: PlaybackSettings) {
        repository.save(settings)
    }
}
