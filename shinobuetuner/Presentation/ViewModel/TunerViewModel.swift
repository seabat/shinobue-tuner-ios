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
    @Published var lastSavedRecording: RecordingFile? = nil

    // MARK: - 内部

    private let useCase: any MonitorPitchUseCaseProtocol
    private let recordingRepository: any RecordingRepository
    private var cancellables = Set<AnyCancellable>()
    private var sessionStartTime: Date = Date()

    /// デフォルトの依存性を使って初期化（本番用）
    convenience init() {
        let repository = PitchRepositoryImpl()
        let useCase = MonitorPitchUseCase(repository: repository)
        self.init(useCase: useCase, recordingRepository: RecordingRepositoryImpl())
    }

    /// テスト時にモックを注入できる初期化
    init(useCase: any MonitorPitchUseCaseProtocol, recordingRepository: any RecordingRepository = RecordingRepositoryImpl()) {
        self.useCase = useCase
        self.recordingRepository = recordingRepository
    }

    // MARK: - 操作

    /// マイクのアクセス許可を要求する
    func requestPermission() async {
        let granted = await useCase.requestPermission()
        permissionGranted = granted
    }

    /// ピッチ監視を開始する
    func startMonitoring() {
        sessionStartTime = Date()
        pitchHistory = []
        currentTime = 0
        isRunning = true

        // グラフの時間軸を動かすタイマー（0.05秒ごと）
        Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                currentTime = Date().timeIntervalSince(sessionStartTime)
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
    }

    /// ピッチ監視 + 録音を開始する
    func startRecording() {
        let url = recordingRepository.newRecordingURL()
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
        // ContentView が onChange で検知して録音一覧をリロードする
        lastSavedRecording = recordingRepository.fetchAll().first
    }

    // MARK: - 内部処理

    /// 新しいピッチ値を受け取って状態を更新する
    private func handleNewPitch(_ pitch: Float) {
        currentPitch = pitch

        if pitch > 0 {
            // 音符情報を更新
            noteResult = NoteHelper.closestNote(for: pitch)

            // ピッチ履歴を更新（currentTime はタイマーが管理）
            let sample = PitchSample(time: currentTime, frequency: pitch)
            pitchHistory.append(sample)

            // 5秒より古いデータを削除
            pitchHistory.removeAll { $0.time < currentTime - 5.0 }
        } else {
            noteResult = nil
        }
    }
}
