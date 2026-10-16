//
//  FrequencyTableViewModel.swift
//  shinobuetuner
//
//  周波数表画面の状態管理ViewModel

import Combine
import Foundation

/// 周波数表の1行分の表示データ
struct FrequencyTableRow: Identifiable {
    let midiNote: Int
    let fingeringName: String
    let solfegeName: String
    let westernName: String
    let frequency: Double
    let isHighlighted: Bool

    var id: Int { midiNote }
}

/// 周波数表画面の状態を管理するViewModel
final class FrequencyTableViewModel: ObservableObject {
    /// 選択中の調子（チューナー設定から読み込む）
    @Published private(set) var tuning: ShinobueTuning
    /// 階名の表示方式（チューナー設定から読み込む）
    @Published private(set) var solfegeSystem: SolfegeSystem

    /// ハイライトする行（六本調子の MIDI ノート番号: 一（メリ）= A4、1' = B♭6）
    private static let highlightedRokuHonMidiNotes: Set<Int> = [69, 94]

    private let fetchTunerSettingsUseCase: any FetchTunerSettingsUseCaseProtocol

    /// 本番用の依存性で初期化
    convenience init() {
        self.init(fetchTunerSettingsUseCase: FetchTunerSettingsUseCase(repository: TunerSettingsRepositoryImpl()))
    }

    /// テスト・Preview 用に UseCase を差し替えられる初期化
    init(fetchTunerSettingsUseCase: any FetchTunerSettingsUseCaseProtocol) {
        self.fetchTunerSettingsUseCase = fetchTunerSettingsUseCase
        let settings = fetchTunerSettingsUseCase()
        self.tuning = settings.tuning
        self.solfegeSystem = settings.solfegeSystem
    }

    /// 設定値を再読み込みする（画面表示時・設定モーダルを閉じた後。チューナータブでも同じ設定を変更できるため）
    func reloadSettings() {
        let settings = fetchTunerSettingsUseCase()
        tuning = settings.tuning
        solfegeSystem = settings.solfegeSystem
    }

    /// ナビゲーションタイトル（例: "八本調子 周波数表"）
    var title: String {
        String(format: String(localized: "frequencyTable.title.format", defaultValue: "%@ 周波数表"), tuning.displayName)
    }

    /// 表の行（高い音から順）。六本調子の運指を調子の半音差だけずらして求める
    var rows: [FrequencyTableRow] {
        NoteHelper.rokuHonFingeringRange.reversed().map { rokuHonMidiNote in
            let midiNote = rokuHonMidiNote + tuning.semitoneOffset
            return FrequencyTableRow(
                midiNote: midiNote,
                fingeringName: NoteHelper.fingeringName(midiNote: midiNote, tuning: tuning) ?? "",
                solfegeName: NoteHelper.solfegeName(midiNote: midiNote, system: solfegeSystem, tuning: tuning),
                westernName: NoteHelper.westernName(midiNote: midiNote, tuning: tuning),
                frequency: NoteHelper.frequency(midiNote: midiNote),
                isHighlighted: Self.highlightedRokuHonMidiNotes.contains(rokuHonMidiNote)
            )
        }
    }
}
