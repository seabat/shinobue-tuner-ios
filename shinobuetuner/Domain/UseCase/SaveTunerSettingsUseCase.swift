//
//  SaveTunerSettingsUseCase.swift
//  shinobuetuner
//
//  チューナー設定保存ユースケース

import Foundation

/// チューナー設定を保存するユースケースのプロトコル
protocol SaveTunerSettingsUseCaseProtocol {
    func callAsFunction(_ settings: TunerSettings)
}

/// チューナー設定を保存するユースケースの具体実装
final class SaveTunerSettingsUseCase: SaveTunerSettingsUseCaseProtocol {
    private let repository: any TunerSettingsRepository

    init(repository: any TunerSettingsRepository) {
        self.repository = repository
    }

    func callAsFunction(_ settings: TunerSettings) {
        repository.save(settings)
    }
}
