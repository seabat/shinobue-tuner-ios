//
//  FetchHasSelectedGaugeDisplayModeUseCase.swift
//  shinobuetuner
//
//  ゲージ表示方式の選択完了状況取得ユースケース

import Foundation

/// ゲージ表示方式の選択を完了済みかどうかを取得するユースケースのプロトコル
protocol FetchHasSelectedGaugeDisplayModeUseCaseProtocol {
    func callAsFunction() -> Bool
}

/// ゲージ表示方式の選択を完了済みかどうかを取得するユースケースの具体実装
final class FetchHasSelectedGaugeDisplayModeUseCase: FetchHasSelectedGaugeDisplayModeUseCaseProtocol {
    private let repository: any OnboardingRepository

    init(repository: any OnboardingRepository) {
        self.repository = repository
    }

    func callAsFunction() -> Bool {
        repository.hasSelectedGaugeDisplayMode()
    }
}
