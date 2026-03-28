//
//  PlaybackSettingsRepositoryImpl.swift
//  shinobuetuner
//
//  PlaybackSettingsRepository の UserDefaults 実装

import Foundation

/// PlaybackSettingsRepository の UserDefaults を使った具体実装
final class PlaybackSettingsRepositoryImpl: PlaybackSettingsRepository {
    private enum Keys {
        static let trimNoisePeakThreshold = "trimNoisePeakThreshold"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetch() -> PlaybackSettings {
        let saved = defaults.float(forKey: Keys.trimNoisePeakThreshold)
        return PlaybackSettings(
            // 未保存（0.0）の場合はデフォルト値を使う
            trimNoisePeakThreshold: saved > 0 ? saved : 0.003
        )
    }

    func save(_ settings: PlaybackSettings) {
        defaults.set(settings.trimNoisePeakThreshold, forKey: Keys.trimNoisePeakThreshold)
    }
}
