//
//  OnboardingRepositoryImpl.swift
//  shinobuetuner
//
//  OnboardingRepository の UserDefaults 実装

import Foundation

/// OnboardingRepository の UserDefaults を使った具体実装
final class OnboardingRepositoryImpl: OnboardingRepository {
    private enum Keys {
        static let hasSelectedTuning = "hasSelectedTuning"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasSelectedTuning() -> Bool {
        // 未保存時は false → 既存ユーザーを含め、初回起動時に調子選択を表示する
        defaults.bool(forKey: Keys.hasSelectedTuning)
    }

    func markTuningSelected() {
        defaults.set(true, forKey: Keys.hasSelectedTuning)
    }
}
