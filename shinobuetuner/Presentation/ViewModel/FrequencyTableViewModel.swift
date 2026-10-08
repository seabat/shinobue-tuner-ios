//
//  FrequencyTableViewModel.swift
//  shinobuetuner
//
//  周波数表画面の状態管理ViewModel

import Combine
import Foundation

/// 周波数表画面の状態を管理するViewModel
final class FrequencyTableViewModel: ObservableObject {
    /// 階名の表示方式（チューナー設定から読み込む）
    @Published private(set) var solfegeSystem: SolfegeSystem

    private let fetchTunerSettingsUseCase: any FetchTunerSettingsUseCaseProtocol

    /// 本番用の依存性で初期化
    convenience init() {
        self.init(fetchTunerSettingsUseCase: FetchTunerSettingsUseCase(repository: TunerSettingsRepositoryImpl()))
    }

    /// テスト・Preview 用に UseCase を差し替えられる初期化
    init(fetchTunerSettingsUseCase: any FetchTunerSettingsUseCaseProtocol) {
        self.fetchTunerSettingsUseCase = fetchTunerSettingsUseCase
        self.solfegeSystem = fetchTunerSettingsUseCase().solfegeSystem
    }

    /// 設定値を再読み込みする（チューナータブで設定が変わる可能性があるため、画面表示のたびに呼ぶ）
    func reloadSettings() {
        solfegeSystem = fetchTunerSettingsUseCase().solfegeSystem
    }

    /// MIDIノート番号から現在の表示方式の階名を返す
    func solfegeName(midiNote: Int) -> String {
        NoteHelper.solfegeName(midiNote: midiNote, system: solfegeSystem)
    }
}
