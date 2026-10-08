//
//  MarkTuningSelectedUseCase.swift
//  shinobuetuner
//
//  調子選択の完了記録ユースケース

import Foundation

/// 調子選択を完了済みとして記録するユースケースのプロトコル
protocol MarkTuningSelectedUseCaseProtocol {
    func callAsFunction()
}

/// 調子選択を完了済みとして記録するユースケースの具体実装
final class MarkTuningSelectedUseCase: MarkTuningSelectedUseCaseProtocol {
    private let repository: any OnboardingRepository

    init(repository: any OnboardingRepository) {
        self.repository = repository
    }

    func callAsFunction() {
        repository.markTuningSelected()
    }
}
