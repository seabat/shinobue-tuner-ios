//
//  TuningSelectionViewModel.swift
//  shinobuetuner
//
//  初回起動時の調子選択画面の状態管理ViewModel

import Combine
import Foundation

/// 初回起動時の調子選択画面の状態を管理するViewModel
final class TuningSelectionViewModel: ObservableObject {
    /// 選択中の調子（初期値は現在保存されている調子）
    @Published var tuning: ShinobueTuning

    private let fetchTunerSettingsUseCase: any FetchTunerSettingsUseCaseProtocol
    private let saveTunerSettingsUseCase: any SaveTunerSettingsUseCaseProtocol
    private let markTuningSelectedUseCase: any MarkTuningSelectedUseCaseProtocol

    /// 本番用の依存性で初期化
    convenience init() {
        let settingsRepository = TunerSettingsRepositoryImpl()
        self.init(
            fetchTunerSettingsUseCase: FetchTunerSettingsUseCase(repository: settingsRepository),
            saveTunerSettingsUseCase: SaveTunerSettingsUseCase(repository: settingsRepository),
            markTuningSelectedUseCase: MarkTuningSelectedUseCase(repository: OnboardingRepositoryImpl())
        )
    }

    /// テスト・Preview 用に UseCase を差し替えられる初期化
    init(
        fetchTunerSettingsUseCase: any FetchTunerSettingsUseCaseProtocol,
        saveTunerSettingsUseCase: any SaveTunerSettingsUseCaseProtocol,
        markTuningSelectedUseCase: any MarkTuningSelectedUseCaseProtocol
    ) {
        self.fetchTunerSettingsUseCase = fetchTunerSettingsUseCase
        self.saveTunerSettingsUseCase = saveTunerSettingsUseCase
        self.markTuningSelectedUseCase = markTuningSelectedUseCase
        self.tuning = fetchTunerSettingsUseCase().tuning
    }

    /// 選択した調子を保存し、調子選択を完了済みとして記録する
    func confirm() {
        // 調子以外の設定値を保持するため、保存前に最新の設定を読み直す
        var settings = fetchTunerSettingsUseCase()
        settings.tuning = tuning
        saveTunerSettingsUseCase(settings)
        markTuningSelectedUseCase()
    }
}
