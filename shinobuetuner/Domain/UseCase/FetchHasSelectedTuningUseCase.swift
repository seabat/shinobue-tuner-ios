//
//  FetchHasSelectedTuningUseCase.swift
//  shinobuetuner
//
//  調子選択の完了状況取得ユースケース

import Foundation

/// 調子選択を完了済みかどうかを取得するユースケースのプロトコル
protocol FetchHasSelectedTuningUseCaseProtocol {
    func callAsFunction() -> Bool
}

/// 調子選択を完了済みかどうかを取得するユースケースの具体実装
final class FetchHasSelectedTuningUseCase: FetchHasSelectedTuningUseCaseProtocol {
    private let repository: any OnboardingRepository

    init(repository: any OnboardingRepository) {
        self.repository = repository
    }

    func callAsFunction() -> Bool {
        repository.hasSelectedTuning()
    }
}
