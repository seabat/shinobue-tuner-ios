//
//  TunerSettingsViewModel.swift
//  shinobuetuner
//
//  チューナー設定画面の状態管理ViewModel

import Combine
import Foundation

/// チューナー設定画面の状態を管理するViewModel
final class TunerSettingsViewModel: ObservableObject {
    /// 設定値（変更時に即座に永続化）
    @Published var settings: TunerSettings {
        didSet { saveUseCase(settings) }
    }

    private let saveUseCase: any SaveTunerSettingsUseCaseProtocol

    /// 本番用の依存性で初期化
    convenience init() {
        let repository = TunerSettingsRepositoryImpl()
        self.init(
            fetchUseCase: FetchTunerSettingsUseCase(repository: repository),
            saveUseCase: SaveTunerSettingsUseCase(repository: repository)
        )
    }

    /// テスト・Preview 用に UseCase を差し替えられる初期化
    init(
        fetchUseCase: any FetchTunerSettingsUseCaseProtocol,
        saveUseCase: any SaveTunerSettingsUseCaseProtocol
    ) {
        self.saveUseCase = saveUseCase
        // fetchUseCase は初期値の取得のみに使い、init 後は保持しない
        _settings = Published(initialValue: fetchUseCase())
    }
}
