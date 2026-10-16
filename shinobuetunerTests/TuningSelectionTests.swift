//
//  TuningSelectionTests.swift
//  shinobuetunerTests
//
//  初回起動時の調子選択（表示判定・保存）を検証する

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
private final class InMemoryOnboarding: FetchHasSelectedTuningUseCaseProtocol, MarkTuningSelectedUseCaseProtocol {
    var hasSelectedTuning: Bool

    init(hasSelectedTuning: Bool) {
        self.hasSelectedTuning = hasSelectedTuning
    }

    func callAsFunction() -> Bool { hasSelectedTuning }
    func callAsFunction() { hasSelectedTuning = true }
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
struct TuningSelectionTests {

    @Test("調子選択画面の初期値は現在保存されている調子")
    func initialTuningIsCurrentSetting() {
        let settings = InMemoryTunerSettings(settings: TunerSettings(tuning: .hachihon))
        let viewModel = TuningSelectionViewModel(
            fetchTunerSettingsUseCase: settings,
            saveTunerSettingsUseCase: settings,
            markTuningSelectedUseCase: InMemoryOnboarding(hasSelectedTuning: false)
        )

        #expect(viewModel.tuning == .hachihon)
    }

    @Test("決定すると調子が保存され、調子選択が完了済みとして記録される（他の設定値は保持）")
    func confirmSavesTuningAndMarksSelected() {
        let settings = InMemoryTunerSettings(settings: TunerSettings(centThreshold: 25, tuning: .rokuHon))
        let onboarding = InMemoryOnboarding(hasSelectedTuning: false)
        let viewModel = TuningSelectionViewModel(
            fetchTunerSettingsUseCase: settings,
            saveTunerSettingsUseCase: settings,
            markTuningSelectedUseCase: onboarding
        )

        viewModel.tuning = .hachihon
        viewModel.confirm()

        #expect(settings.settings.tuning == .hachihon)
        #expect(settings.settings.centThreshold == 25)
        #expect(onboarding.hasSelectedTuning)
    }

    @Test("未選択なら、マイク許可の問い合わせ後に調子選択を表示する（許可・拒否どちらでも）", arguments: [true, false])
    func showsSelectionAfterPermissionWhenNotSelected(permissionGranted: Bool) async {
        let viewModel = makeTunerViewModel(permissionGranted: permissionGranted, hasSelectedTuning: false)
        #expect(!viewModel.shouldShowTuningSelection)

        await viewModel.requestPermission()

        #expect(viewModel.permissionGranted == permissionGranted)
        #expect(viewModel.shouldShowTuningSelection)
    }

    @Test("選択済みなら、マイク許可の問い合わせ後も調子選択を表示しない", arguments: [true, false])
    func doesNotShowSelectionWhenAlreadySelected(permissionGranted: Bool) async {
        let viewModel = makeTunerViewModel(permissionGranted: permissionGranted, hasSelectedTuning: true)

        await viewModel.requestPermission()

        #expect(!viewModel.shouldShowTuningSelection)
    }

    @Test("チューナー設定を「デフォルトに戻す」で保存しても、調子選択の完了記録は消えない")
    func resetTunerSettingsKeepsSelectionRecord() throws {
        let suiteName = "TuningSelectionTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let onboardingRepository = OnboardingRepositoryImpl(defaults: defaults)
        let settingsRepository = TunerSettingsRepositoryImpl(defaults: defaults)
        #expect(!onboardingRepository.hasSelectedTuning())

        onboardingRepository.markTuningSelected()
        settingsRepository.save(TunerSettings(tuning: .hachihon))
        // 「デフォルトに戻す」相当
        settingsRepository.save(TunerSettings())

        #expect(onboardingRepository.hasSelectedTuning())
        #expect(settingsRepository.fetch().tuning == .rokuHon)
    }

    private func makeTunerViewModel(permissionGranted: Bool, hasSelectedTuning: Bool) -> TunerViewModel {
        TunerViewModel(
            useCase: StubMonitorPitchUseCase(permissionGranted: permissionGranted),
            playbackFileRepository: PlaybackFileRepositoryImpl(),
            fetchTunerSettingsUseCase: InMemoryTunerSettings(),
            fetchHasSelectedTuningUseCase: InMemoryOnboarding(hasSelectedTuning: hasSelectedTuning)
        )
    }
}
