//
//  GaugeDisplayModeSelectionTests.swift
//  shinobuetunerTests
//
//  初回起動時のゲージ表示方式選択（表示判定・保存・調子選択との連鎖）を検証する

import Combine
import Foundation
import Testing
@testable import shinobuetuner

// MARK: - テスト用モック

/// メモリ上で設定を保持するチューナー設定 UseCase のモック
private final class InMemoryTunerSettings: FetchTunerSettingsUseCaseProtocol, SaveTunerSettingsUseCaseProtocol {
    var settings: TunerSettings

    init(settings: TunerSettings = TunerSettings()) {
        self.settings = settings
    }

    func callAsFunction() -> TunerSettings { settings }
    func callAsFunction(_ settings: TunerSettings) { self.settings = settings }
}

/// 調子選択の完了状況を保持する UseCase のモック
private final class InMemoryTuningOnboarding: FetchHasSelectedTuningUseCaseProtocol {
    let hasSelectedTuning: Bool

    init(hasSelectedTuning: Bool) {
        self.hasSelectedTuning = hasSelectedTuning
    }

    func callAsFunction() -> Bool { hasSelectedTuning }
}

/// ゲージ表示方式の選択完了状況を保持する UseCase のモック
private final class InMemoryGaugeOnboarding: FetchHasSelectedGaugeDisplayModeUseCaseProtocol, MarkGaugeDisplayModeSelectedUseCaseProtocol {
    var hasSelectedGaugeDisplayMode: Bool

    init(hasSelectedGaugeDisplayMode: Bool) {
        self.hasSelectedGaugeDisplayMode = hasSelectedGaugeDisplayMode
    }

    func callAsFunction() -> Bool { hasSelectedGaugeDisplayMode }
    func callAsFunction() { hasSelectedGaugeDisplayMode = true }
}

/// マイク許可の結果だけを差し替えるピッチ監視 UseCase のモック
private final class StubMonitorPitchUseCase: MonitorPitchUseCaseProtocol {
    let permissionGranted: Bool

    init(permissionGranted: Bool) {
        self.permissionGranted = permissionGranted
    }

    var pitchPublisher: AnyPublisher<Float, Never> { Empty().eraseToAnyPublisher() }
    var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> { Empty().eraseToAnyPublisher() }
    func start() {}
    func stop() {}
    func requestPermission() async -> Bool { permissionGranted }
    func startRecording(to url: URL) throws {}
    func stopRecording() {}
}

// MARK: - テスト

@MainActor
struct GaugeDisplayModeSelectionTests {

    // MARK: 設定モデル

    @Test("ゲージ表示方式のデフォルトは音階名")
    func defaultGaugeDisplayModeIsNoteName() {
        #expect(TunerSettings().gaugeDisplayMode == .noteName)
    }

    // MARK: 選択画面の ViewModel

    @Test("表示方式選択画面の初期値は現在保存されている表示方式")
    func initialModeIsCurrentSetting() {
        let settings = InMemoryTunerSettings(settings: TunerSettings(gaugeDisplayMode: .fingering))
        let viewModel = GaugeDisplayModeSelectionViewModel(
            fetchTunerSettingsUseCase: settings,
            saveTunerSettingsUseCase: settings,
            markGaugeDisplayModeSelectedUseCase: InMemoryGaugeOnboarding(hasSelectedGaugeDisplayMode: false)
        )

        #expect(viewModel.gaugeDisplayMode == .fingering)
    }

    @Test("決定すると表示方式が保存され、完了済みとして記録される（他の設定値は保持）")
    func confirmSavesModeAndMarksSelected() {
        let settings = InMemoryTunerSettings(settings: TunerSettings(centThreshold: 25, tuning: .hachihon))
        let onboarding = InMemoryGaugeOnboarding(hasSelectedGaugeDisplayMode: false)
        let viewModel = GaugeDisplayModeSelectionViewModel(
            fetchTunerSettingsUseCase: settings,
            saveTunerSettingsUseCase: settings,
            markGaugeDisplayModeSelectedUseCase: onboarding
        )

        viewModel.gaugeDisplayMode = .fingering
        viewModel.confirm()

        #expect(settings.settings.gaugeDisplayMode == .fingering)
        #expect(settings.settings.centThreshold == 25)
        #expect(settings.settings.tuning == .hachihon)
        #expect(onboarding.hasSelectedGaugeDisplayMode)
    }

    // MARK: サンプル表示

    // 運指名・階名はローカライズ文字列のため、ここでは調子に依存しない西洋音階名のみ厳密に検証する
    // （運指名・階名の文字列そのものは NoteHelperTuningTests が日本語ロケールで検証している）

    @Test("サンプルは運指「一」（調子の主音）になる", arguments: [
        (ShinobueTuning.rokuHon, "B♭4"),
        (ShinobueTuning.hachihon, "C5")
    ])
    func sampleIsTonicOfSelectedTuning(tuning: ShinobueTuning, expectedWesternName: String) {
        let settings = InMemoryTunerSettings(settings: TunerSettings(tuning: tuning))
        let viewModel = GaugeDisplayModeSelectionViewModel(
            fetchTunerSettingsUseCase: settings,
            saveTunerSettingsUseCase: settings,
            markGaugeDisplayModeSelectedUseCase: InMemoryGaugeOnboarding(hasSelectedGaugeDisplayMode: false)
        )

        #expect(viewModel.sampleWesternName == expectedWesternName)
        #expect(!viewModel.sampleFingeringName.isEmpty)
        #expect(!viewModel.sampleSolfegeName.isEmpty)
    }

    @Test("サンプルの階名は移動ド／固定ドの設定に従う", arguments: [SolfegeSystem.movable, SolfegeSystem.fixed])
    func sampleSolfegeFollowsSetting(system: SolfegeSystem) {
        let settings = InMemoryTunerSettings(settings: TunerSettings(tuning: .rokuHon, solfegeSystem: system))
        let viewModel = GaugeDisplayModeSelectionViewModel(
            fetchTunerSettingsUseCase: settings,
            saveTunerSettingsUseCase: settings,
            markGaugeDisplayModeSelectedUseCase: InMemoryGaugeOnboarding(hasSelectedGaugeDisplayMode: false)
        )

        let expected = NoteHelper.solfegeName(midiNote: 70, system: system, tuning: .rokuHon)
        #expect(viewModel.sampleSolfegeName == expected)
    }

    // MARK: 表示判定（調子選択との連鎖）

    @Test("既存ユーザー（調子は選択済み・表示方式は未選択）には、マイク許可の問い合わせ後に表示方式選択を出す", arguments: [true, false])
    func showsGaugeSelectionForExistingUser(permissionGranted: Bool) async {
        let viewModel = makeTunerViewModel(
            permissionGranted: permissionGranted,
            hasSelectedTuning: true,
            hasSelectedGaugeDisplayMode: false
        )
        #expect(!viewModel.shouldShowGaugeDisplayModeSelection)

        await viewModel.requestPermission()

        #expect(!viewModel.shouldShowTuningSelection)
        #expect(viewModel.shouldShowGaugeDisplayModeSelection)
    }

    @Test("どちらも選択済みなら、どちらのモーダルも表示しない")
    func showsNothingWhenAllSelected() async {
        let viewModel = makeTunerViewModel(
            permissionGranted: true,
            hasSelectedTuning: true,
            hasSelectedGaugeDisplayMode: true
        )

        await viewModel.requestPermission()

        #expect(!viewModel.shouldShowTuningSelection)
        #expect(!viewModel.shouldShowGaugeDisplayModeSelection)
    }

    @Test("新規ユーザーでは、まず調子選択だけを出し、表示方式選択は同時に出さない")
    func showsTuningFirstForNewUser() async {
        let viewModel = makeTunerViewModel(
            permissionGranted: true,
            hasSelectedTuning: false,
            hasSelectedGaugeDisplayMode: false
        )

        await viewModel.requestPermission()

        #expect(viewModel.shouldShowTuningSelection)
        #expect(!viewModel.shouldShowGaugeDisplayModeSelection)
    }

    @Test("調子選択を閉じた後の判定で、未選択なら表示方式選択を出す")
    func showsGaugeSelectionAfterTuningDismissed() async {
        let viewModel = makeTunerViewModel(
            permissionGranted: true,
            hasSelectedTuning: false,
            hasSelectedGaugeDisplayMode: false
        )
        await viewModel.requestPermission()

        // ContentView の onDismiss 相当
        viewModel.evaluateGaugeDisplayModeSelection()

        #expect(viewModel.shouldShowGaugeDisplayModeSelection)
    }

    @Test("調子選択を閉じた後でも、表示方式が選択済みならモーダルを出さない")
    func doesNotShowGaugeSelectionWhenAlreadySelected() async {
        let viewModel = makeTunerViewModel(
            permissionGranted: true,
            hasSelectedTuning: false,
            hasSelectedGaugeDisplayMode: true
        )
        await viewModel.requestPermission()

        viewModel.evaluateGaugeDisplayModeSelection()

        #expect(!viewModel.shouldShowGaugeDisplayModeSelection)
    }

    // MARK: 永続化

    @Test("チューナー設定を「デフォルトに戻す」で保存しても、表示方式選択の完了記録は消えない")
    func resetTunerSettingsKeepsGaugeSelectionRecord() throws {
        let suiteName = "GaugeDisplayModeSelectionTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let onboardingRepository = OnboardingRepositoryImpl(defaults: defaults)
        let settingsRepository = TunerSettingsRepositoryImpl(defaults: defaults)
        #expect(!onboardingRepository.hasSelectedGaugeDisplayMode())

        onboardingRepository.markGaugeDisplayModeSelected()
        settingsRepository.save(TunerSettings(gaugeDisplayMode: .fingering))
        #expect(settingsRepository.fetch().gaugeDisplayMode == .fingering)

        // 「デフォルトに戻す」相当：設定は初期化されるが、完了記録は残る
        settingsRepository.save(TunerSettings())

        #expect(onboardingRepository.hasSelectedGaugeDisplayMode())
        #expect(settingsRepository.fetch().gaugeDisplayMode == .noteName)
    }

    @Test("未保存の UserDefaults では表示方式は音階名・選択は未完了として扱う")
    func unsavedDefaultsAreTreatedAsNotSelected() throws {
        let suiteName = "GaugeDisplayModeSelectionTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(!OnboardingRepositoryImpl(defaults: defaults).hasSelectedGaugeDisplayMode())
        #expect(TunerSettingsRepositoryImpl(defaults: defaults).fetch().gaugeDisplayMode == .noteName)
    }

    // MARK: ヘルパー

    private func makeTunerViewModel(
        permissionGranted: Bool,
        hasSelectedTuning: Bool,
        hasSelectedGaugeDisplayMode: Bool
    ) -> TunerViewModel {
        TunerViewModel(
            useCase: StubMonitorPitchUseCase(permissionGranted: permissionGranted),
            playbackFileRepository: PlaybackFileRepositoryImpl(),
            fetchTunerSettingsUseCase: InMemoryTunerSettings(),
            fetchHasSelectedTuningUseCase: InMemoryTuningOnboarding(hasSelectedTuning: hasSelectedTuning),
            fetchHasSelectedGaugeDisplayModeUseCase: InMemoryGaugeOnboarding(hasSelectedGaugeDisplayMode: hasSelectedGaugeDisplayMode)
        )
    }
}
