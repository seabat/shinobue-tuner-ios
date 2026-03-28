//
//  TunerViewModel.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  チューナー画面の状態管理ViewModel

import Foundation
import Combine

/// チューナー画面の状態を管理するViewModel
@MainActor
final class TunerViewModel: ObservableObject {
    // MARK: - 公開状態

    /// 現在の周波数（Hz）、無音時は0
    @Published var currentPitch: Float = 0
    /// 最近傍の音符情報とセント偏差
    @Published var noteResult: (note: NoteInfo, cents: Float)? = nil
    /// 過去5秒間のピッチ履歴
    @Published var pitchHistory: [PitchSample] = []
    /// 録音中かどうか
    @Published var isRunning: Bool = false
    /// マイクの許可が得られているかどうか
    @Published var permissionGranted: Bool = false
    /// セッション開始からの経過時間（録音中は常に更新される）
    @Published var currentTime: TimeInterval = 0
    /// 録音中かどうか（ピッチ監視とは独立）
    @Published var isSavingRecording: Bool = false
    /// 直近に保存した録音ファイル（ContentView が一覧を更新するトリガーに使う）
    @Published var lastSavedRecording: PlaybackFile? = nil

    /// チューニング成功エフェクトのトリガー（false→true への変化でエフェクト発火）
    @Published var showTuningCelebration: Bool = false
    /// 30秒間無音で自動停止したことを通知するアラートトリガー
    @Published var showSilenceTimeoutAlert: Bool = false
    /// 自動停止時のモード（アラートメッセージの切り替えに使用）
    @Published var silenceTimeoutWasRecording: Bool = false

    /// チューナー設定値（設定モーダルを閉じたタイミングで reloadSettings() により更新）
    @Published var tunerSettings: TunerSettings

    // MARK: - 内部

    private let useCase: any MonitorPitchUseCaseProtocol
    private let playbackFileRepository: any PlaybackFileRepository
    private let fetchSettingsUseCase: any FetchTunerSettingsUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private var sessionStartTime: Date = Date()
    /// 最後に音を検出した currentTime（無音タイムアウト判定に使用）
    private var lastSoundTime: TimeInterval = 0
    /// 無音が続いたら自動停止するまでの秒数
    private let silenceTimeoutSeconds: TimeInterval = 30

    /// チューニング成功判定の状態機械
    private enum InTuneState {
        case idle
        case accumulating(midiNote: Int, since: TimeInterval)
        case cooling(midiNote: Int, until: TimeInterval)
    }
    private var inTuneState: InTuneState = .idle

    /// デフォルトの依存性を使って初期化（本番用）
    convenience init() {
        let settingsRepository = TunerSettingsRepositoryImpl()
        self.init(
            useCase: MonitorPitchUseCase(repository: PitchRepositoryImpl()),
            playbackFileRepository: PlaybackFileRepositoryImpl(),
            fetchSettingsUseCase: FetchTunerSettingsUseCase(repository: settingsRepository)
        )
    }

    /// テスト・Preview 用にモック UseCase だけを差し替えられる便利イニシャライザ
    convenience init(useCase: any MonitorPitchUseCaseProtocol) {
        let settingsRepository = TunerSettingsRepositoryImpl()
        self.init(
            useCase: useCase,
            playbackFileRepository: PlaybackFileRepositoryImpl(),
            fetchSettingsUseCase: FetchTunerSettingsUseCase(repository: settingsRepository)
        )
    }

    /// 全依存性を注入できる指定イニシャライザ（完全なモック差し替えが必要なテスト用）
    init(
        useCase: any MonitorPitchUseCaseProtocol,
        playbackFileRepository: any PlaybackFileRepository,
        fetchSettingsUseCase: any FetchTunerSettingsUseCaseProtocol
    ) {
        self.useCase = useCase
        self.playbackFileRepository = playbackFileRepository
        self.fetchSettingsUseCase = fetchSettingsUseCase
        self.tunerSettings = fetchSettingsUseCase()
    }

    // MARK: - 操作

    /// マイクのアクセス許可を要求する
    func requestPermission() async {
        let granted = await useCase.requestPermission()
        permissionGranted = granted
    }

    /// 設定モーダルを閉じた後に設定値を再読み込みする
    func reloadSettings() {
        tunerSettings = fetchSettingsUseCase()
    }

    /// ピッチ監視を開始する
    func startMonitoring() {
        sessionStartTime = Date()
        pitchHistory = []
        currentTime = 0
        lastSoundTime = 0
        isRunning = true

        // グラフの時間軸を動かすタイマー（0.05秒ごと）
        Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                currentTime = Date().timeIntervalSince(sessionStartTime)
                // 30秒間無音が続いたら自動停止
                if currentTime - lastSoundTime >= silenceTimeoutSeconds {
                    autoStopDueToSilence()
                }
            }
            .store(in: &cancellables)

        useCase.pitchPublisher
            .sink { [weak self] pitch in
                self?.handleNewPitch(pitch)
            }
            .store(in: &cancellables)

        useCase.start()
    }

    /// ピッチ監視を停止する
    func stopMonitoring() {
        useCase.stop()
        cancellables.removeAll()
        isRunning = false
        currentPitch = 0
        currentTime = 0
        noteResult = nil
        resetInTuneState()
    }

    /// ピッチ監視 + 録音を開始する
    func startRecording() {
        let url = playbackFileRepository.newPlaybackFileURL()
        startMonitoring()
        do {
            try useCase.startRecording(to: url)
            isSavingRecording = true
        } catch {
            print("録音開始エラー: \(error)")
        }
    }

    /// 録音を停止してファイルを保存する
    func stopRecording() {
        useCase.stopRecording()
        isSavingRecording = false
        stopMonitoring()
        // ContentView が onChange で検知して音声ファイル一覧をリロードする
        lastSavedRecording = playbackFileRepository.fetchAll().first
    }

    // MARK: - 内部処理

    /// 新しいピッチ値を受け取って状態を更新する
    private func handleNewPitch(_ pitch: Float) {
        currentPitch = pitch

        if pitch > 0 {
            // 音を検出した時刻を更新（無音タイムアウトのリセット）
            lastSoundTime = currentTime

            // 音符情報を更新
            let result = NoteHelper.closestNote(for: pitch)
            noteResult = result

            // ピッチ履歴を更新（currentTime はタイマーが管理）
            let sample = PitchSample(time: currentTime, frequency: pitch)
            pitchHistory.append(sample)

            // 5秒より古いデータを削除
            pitchHistory.removeAll { $0.time < currentTime - 5.0 }

            // チューニング成功判定
            if let r = result {
                updateInTuneState(midiNote: r.note.midiNote, cents: r.cents)
            } else {
                resetInTuneState()
            }
        } else {
            noteResult = nil
            resetInTuneState()
        }
    }

    /// チューニング成功判定の状態を更新する
    private func updateInTuneState(midiNote: Int, cents: Float) {
        let isInTune = abs(cents) <= Float(tunerSettings.centThreshold)

        switch inTuneState {
        case .idle:
            if isInTune {
                inTuneState = .accumulating(midiNote: midiNote, since: currentTime)
            }

        case .accumulating(let trackedNote, let since):
            if midiNote != trackedNote {
                // 音階名変更 → 新しい音階名で判定をリセット
                inTuneState = isInTune
                    ? .accumulating(midiNote: midiNote, since: currentTime)
                    : .idle
            } else if !isInTune {
                // 同じ音階名だがズレた → idle
                inTuneState = .idle
            } else if currentTime - since >= tunerSettings.durationSeconds {
                // 設定秒数以上 in-tune → エフェクト発火
                showTuningCelebration = true
                inTuneState = .cooling(midiNote: midiNote, until: currentTime + 1.0)
            }

        case .cooling(let trackedNote, let until):
            if midiNote != trackedNote {
                // 音階名変更 → 即座にリセットして新しい音階名で判定開始
                showTuningCelebration = false
                inTuneState = isInTune
                    ? .accumulating(midiNote: midiNote, since: currentTime)
                    : .idle
            } else if currentTime >= until {
                // クールダウン終了
                showTuningCelebration = false
                inTuneState = isInTune
                    ? .accumulating(midiNote: midiNote, since: currentTime)
                    : .idle
            }
            // クールダウン中は何もしない
        }
    }

    /// 30秒間無音が続いた場合に計測/録音を自動停止する
    private func autoStopDueToSilence() {
        silenceTimeoutWasRecording = isSavingRecording
        if isSavingRecording {
            stopRecording()
        } else {
            stopMonitoring()
        }
        showSilenceTimeoutAlert = true
    }

    /// チューニング判定状態をリセットする
    private func resetInTuneState() {
        inTuneState = .idle
        showTuningCelebration = false
    }
}
