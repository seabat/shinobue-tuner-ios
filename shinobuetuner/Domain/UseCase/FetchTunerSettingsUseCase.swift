//
//  FetchTunerSettingsUseCase.swift
//  shinobuetuner
//
//  チューナー設定取得ユースケース

import Foundation

/// チューナー設定を取得するユースケースのプロトコル
protocol FetchTunerSettingsUseCaseProtocol {
    func callAsFunction() -> TunerSettings
}

/// チューナー設定を取得するユースケースの具体実装
final class FetchTunerSettingsUseCase: FetchTunerSettingsUseCaseProtocol {
    private let repository: any TunerSettingsRepository

    init(repository: any TunerSettingsRepository) {
        self.repository = repository
    }

    func callAsFunction() -> TunerSettings {
        repository.fetch()
    }
}
