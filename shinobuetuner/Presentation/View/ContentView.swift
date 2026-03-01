//
//  ContentView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  ぞめきチューナー - ルートビュー

import SwiftUI
import Combine

/// アプリのルートビュー（ViewModelを保有する）
struct ContentView: View {
    @StateObject private var viewModel: TunerViewModel
    @StateObject private var recordingListViewModel: RecordingListViewModel
    @Environment(\.scenePhase) private var scenePhase

    /// 本番用（デフォルト）
    init() {
        _viewModel = StateObject(wrappedValue: TunerViewModel())
        _recordingListViewModel = StateObject(wrappedValue: RecordingListViewModel())
    }

    /// プレビュー・テスト用（ViewModel を外から注入）
    init(viewModel: TunerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _recordingListViewModel = StateObject(wrappedValue: RecordingListViewModel())
    }

    var body: some View {
        TabView {
            // ─── チューナータブ ───
            Tab("チューナー", systemImage: "tuningfork") {
                ZStack {
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                        .ignoresSafeArea()

                    if viewModel.permissionGranted {
                        TunerMainView(viewModel: viewModel)
                    } else {
                        PermissionRequestView(viewModel: viewModel)
                    }
                }
            }

            // ─── 録音一覧タブ ───
            Tab("録音一覧", systemImage: "list.bullet.rectangle") {
                NavigationStack {
                    RecordingListView(viewModel: recordingListViewModel)
                        .navigationTitle("録音一覧")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .task {
            // 起動時にマイク権限を確認
            await viewModel.requestPermission()
        }
        .onChange(of: viewModel.lastSavedRecording) { _, _ in
            // 録音保存後に一覧を自動更新
            recordingListViewModel.loadRecordings()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // バックグラウンド遷移時、録音中でなければ計測を停止
            if newPhase == .background && viewModel.isRunning && !viewModel.isSavingRecording {
                viewModel.stopMonitoring()
            }
        }
    }
}

// MARK: - Preview

private final class PreviewUseCase: MonitorPitchUseCaseProtocol {
    var pitchPublisher: AnyPublisher<Float, Never> {
        Empty().eraseToAnyPublisher()
    }
    func start() {}
    func stop() {}
    func requestPermission() async -> Bool { true }
    func startRecording(to url: URL) throws {}
    func stopRecording() {}
}

#Preview("権限未許可（初期状態）") {
    ContentView()
}

#Preview("権限許可済み（チューナー画面）") {
    let vm = TunerViewModel(useCase: PreviewUseCase())
    vm.permissionGranted = true
    vm.currentPitch = 295.0
    vm.isRunning = true
    vm.noteResult = NoteHelper.closestNote(for: 295.0)
    vm.pitchHistory = stride(from: 0.0, to: 5.0, by: 0.05).map { t in
        let freq = 295.0 + 10.0 * sin(t * 3.0)
        return PitchSample(time: t, frequency: Float(freq))
    }
    return ContentView(viewModel: vm)
}
