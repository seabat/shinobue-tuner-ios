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
        static let sortOrder = "playbackSortOrder"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetch() -> PlaybackSettings {
        let savedThreshold = defaults.float(forKey: Keys.trimNoisePeakThreshold)
        let savedSortOrder = defaults.string(forKey: Keys.sortOrder)
            .flatMap { PlaybackSortOrder(rawValue: $0) }
        return PlaybackSettings(
            // 未保存（0.0）の場合はデフォルト値を使う
            trimNoisePeakThreshold: savedThreshold > 0 ? savedThreshold : 0.003,
            sortOrder: savedSortOrder ?? .createdAtDescending
        )
    }

    func save(_ settings: PlaybackSettings) {
        defaults.set(settings.trimNoisePeakThreshold, forKey: Keys.trimNoisePeakThreshold)
        defaults.set(settings.sortOrder.rawValue, forKey: Keys.sortOrder)
    }
}
