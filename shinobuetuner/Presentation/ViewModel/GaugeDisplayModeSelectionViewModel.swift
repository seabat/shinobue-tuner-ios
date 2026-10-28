//
//  GaugeDisplayModeSelectionViewModel.swift
//  shinobuetuner
//
//  初回起動時のゲージ表示方式選択画面の状態管理ViewModel

import Combine
import Foundation

/// 初回起動時のゲージ表示方式選択画面の状態を管理するViewModel
final class GaugeDisplayModeSelectionViewModel: ObservableObject {
    /// 選択中の表示方式（初期値は現在保存されている値）
    @Published var gaugeDisplayMode: GaugeDisplayMode

    /// サンプル表示用の階名（保存中の移動ド／固定ドに従う）
    let sampleSolfegeName: String
    /// サンプル表示用の西洋音階名
    let sampleWesternName: String
    /// サンプル表示用の運指名
    let sampleFingeringName: String

    /// サンプルに使う音のMIDIノート番号（六本調子の運指「一」= 主音 = B♭4）
    /// NoteHelper.fingeringName は midiNote - semitoneOffset で引くため、調子の分だけずらす
    private static let sampleFingeringBaseMidiNote = 70

    private let fetchTunerSettingsUseCase: any FetchTunerSettingsUseCaseProtocol
    private let saveTunerSettingsUseCase: any SaveTunerSettingsUseCaseProtocol
    private let markGaugeDisplayModeSelectedUseCase: any MarkGaugeDisplayModeSelectedUseCaseProtocol

    /// 本番用の依存性で初期化
    convenience init() {
        let settingsRepository = TunerSettingsRepositoryImpl()
        self.init(
            fetchTunerSettingsUseCase: FetchTunerSettingsUseCase(repository: settingsRepository),
            saveTunerSettingsUseCase: SaveTunerSettingsUseCase(repository: settingsRepository),
            markGaugeDisplayModeSelectedUseCase: MarkGaugeDisplayModeSelectedUseCase(repository: OnboardingRepositoryImpl())
        )
    }

    /// テスト・Preview 用に UseCase を差し替えられる初期化
    init(
        fetchTunerSettingsUseCase: any FetchTunerSettingsUseCaseProtocol,
        saveTunerSettingsUseCase: any SaveTunerSettingsUseCaseProtocol,
        markGaugeDisplayModeSelectedUseCase: any MarkGaugeDisplayModeSelectedUseCaseProtocol
    ) {
        self.fetchTunerSettingsUseCase = fetchTunerSettingsUseCase
        self.saveTunerSettingsUseCase = saveTunerSettingsUseCase
        self.markGaugeDisplayModeSelectedUseCase = markGaugeDisplayModeSelectedUseCase

        let settings = fetchTunerSettingsUseCase()
        self.gaugeDisplayMode = settings.gaugeDisplayMode

        // サンプルに使う音（運指「一」= 調子の主音）を保存中の調子で解決する
        let midiNote = Self.sampleFingeringBaseMidiNote + settings.tuning.semitoneOffset
        let sample = NoteHelper.closestNote(
            for: Float(NoteHelper.frequency(midiNote: midiNote)),
            tuning: settings.tuning
        )
        self.sampleSolfegeName = sample.map {
            NoteHelper.solfegeName(
                midiNote: $0.note.midiNote,
                system: settings.solfegeSystem,
                tuning: settings.tuning
            )
        } ?? ""
        self.sampleWesternName = sample?.note.westernName ?? ""
        self.sampleFingeringName = sample?.note.fingeringName ?? ""
    }

    /// 選択した表示方式を保存し、選択を完了済みとして記録する
    func confirm() {
        // 表示方式以外の設定値を保持するため、保存前に最新の設定を読み直す
        var settings = fetchTunerSettingsUseCase()
        settings.gaugeDisplayMode = gaugeDisplayMode
        saveTunerSettingsUseCase(settings)
        markGaugeDisplayModeSelectedUseCase()
    }
}
