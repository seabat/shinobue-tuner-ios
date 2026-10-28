//
//  MarkGaugeDisplayModeSelectedUseCase.swift
//  shinobuetuner
//
//  ゲージ表示方式の選択完了記録ユースケース

import Foundation

/// ゲージ表示方式の選択を完了済みとして記録するユースケースのプロトコル
protocol MarkGaugeDisplayModeSelectedUseCaseProtocol {
    func callAsFunction()
}

/// ゲージ表示方式の選択を完了済みとして記録するユースケースの具体実装
final class MarkGaugeDisplayModeSelectedUseCase: MarkGaugeDisplayModeSelectedUseCaseProtocol {
    private let repository: any OnboardingRepository

    init(repository: any OnboardingRepository) {
        self.repository = repository
    }

    func callAsFunction() {
        repository.markGaugeDisplayModeSelected()
    }
}
