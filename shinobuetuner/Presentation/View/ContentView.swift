//
//  ContentView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  篠笛チューナー - ルートビュー

import SwiftUI
import Combine

/// アプリのルートビュー（ViewModelを保有する）
struct ContentView: View {
    @StateObject private var viewModel: TunerViewModel
    @StateObject private var playbackFileListViewModel: PlaybackListViewModel
    @Environment(\.scenePhase) private var scenePhase

    /// 本番用（デフォルト）
    init() {
        _viewModel = StateObject(wrappedValue: TunerViewModel())
        _playbackFileListViewModel = StateObject(wrappedValue: PlaybackListViewModel())
    }

    /// プレビュー・テスト用（ViewModel を外から注入）
    init(viewModel: TunerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _playbackFileListViewModel = StateObject(wrappedValue: PlaybackListViewModel())
    }

    var body: some View {
        TabView {
            // ─── チューナータブ ───
            Tab("チューナー", systemImage: "tuningfork") {
                ZStack {
                    Color("AppBackground")
                        .ignoresSafeArea()

                    if viewModel.permissionGranted {
                        TunerMainScreen(viewModel: viewModel)
                    } else {
                        PermissionRequestView(viewModel: viewModel)
                    }
                }
            }

            // ─── 音声ファイルタブ ───
            Tab("プレイリスト", systemImage: "list.bullet.rectangle") {
                NavigationStack {
                    PlaybackListScreen(viewModel: playbackFileListViewModel)
                }
            }

            // ─── 周波数表タブ ───
            Tab("周波数表", systemImage: "music.note.list") {
                NavigationStack {
                    FrequencyTableScreen()
                        .navigationTitle("六本調子 周波数表")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // 起動時にマイク権限を確認
            await viewModel.requestPermission()
        }
        .onChange(of: viewModel.lastSavedRecording) { _, _ in
            // 録音保存後に一覧を自動更新
            playbackFileListViewModel.loadPlaybackFiles()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // バックグラウンド遷移時、録音中でなければ計測を停止
            if newPhase == .background && viewModel.isRunning && !viewModel.isSavingRecording {
                viewModel.stopMonitoring()
            }
        }
        // 他アプリの共有シートから音声ファイルが送られてきたときにインポートする
        .onOpenURL { url in
            playbackFileListViewModel.importFile(from: url)
        }
    }
}

// MARK: - Preview

private final class PreviewUseCase: MonitorPitchUseCaseProtocol {
    var pitchPublisher: AnyPublisher<Float, Never> {
        Empty().eraseToAnyPublisher()
    }
    var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> {
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
