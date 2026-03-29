//
//  PlaybackSettingsViewModel.swift
//  shinobuetuner
//
//  音声ファイル設定画面の状態管理ViewModel

import Combine
import Foundation

/// 音声ファイル設定画面の状態を管理するViewModel
final class PlaybackSettingsViewModel: ObservableObject {
    /// 設定値（変更時に即座に永続化）
    @Published var settings: PlaybackSettings {
        didSet { saveUseCase(settings) }
    }

    private let saveUseCase: any SavePlaybackSettingsUseCaseProtocol

    /// 本番用の依存性で初期化
    convenience init() {
        let repository = PlaybackSettingsRepositoryImpl()
        self.init(
            fetchUseCase: FetchPlaybackSettingsUseCase(repository: repository),
            saveUseCase: SavePlaybackSettingsUseCase(repository: repository)
        )
    }

    /// テスト・Preview 用に UseCase を差し替えられる初期化
    init(
        fetchUseCase: any FetchPlaybackSettingsUseCaseProtocol,
        saveUseCase: any SavePlaybackSettingsUseCaseProtocol
    ) {
        self.saveUseCase = saveUseCase
        // fetchUseCase は初期値の取得のみに使い、init 後は保持しない
        _settings = Published(initialValue: fetchUseCase())
    }
}
