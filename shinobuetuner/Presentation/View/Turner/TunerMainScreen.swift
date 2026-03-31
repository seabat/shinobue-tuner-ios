//
//  TunerMainScreen.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  チューナーのメイン画面（各サブビューを配置する）

import SwiftUI
import Combine

/// チューナーメインビュー
struct TunerMainScreen: View {
    @ObservedObject var viewModel: TunerViewModel
    @State private var selectedMode: TunerMode = .soloMonitoring
    @State private var isSettingsPresented: Bool = false
    @State private var showEnsembleCountdown: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // ─── 音階名表示エリア ───
            NoteDisplayView(
                noteResult: viewModel.noteResult,
                currentPitch: viewModel.currentPitch
            )
            .frame(height: 160)

            // ─── チューナーメーター ───
            CentsMeterView(
                cents: viewModel.noteResult?.cents ?? 0,
                isActive: viewModel.currentPitch > 0
            )
            .frame(height: 90)
            .padding(.horizontal, 24)
            .padding(.vertical, 4)

            // ─── ピッチグラフ（5秒間） ───
            if viewModel.tunerSettings.showPitchGraph {
                PitchGraphView(
                    pitchHistory: viewModel.pitchHistory,
                    currentTime: viewModel.currentTime
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            } else {
                Spacer()
            }

            // ─── 開始/停止ボタン + モード切替 ───
            ControlBarView(
                viewModel: viewModel,
                selectedMode: $selectedMode,
                showEnsembleCountdown: $showEnsembleCountdown
            )
        }
        .overlay(alignment: .topTrailing) {
            // ─── 設定ボタン ───
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(Color("InactiveMode").opacity(0.7))
                    .padding(12)
            }
            .disabled(viewModel.isRunning)
        }
        .overlay {
            // ─── チューニング成功エフェクト ───
            TuningCelebrationView(isInTune: viewModel.showTuningCelebration)
        }
        // selectedMode の変化を viewModel.tunerMode に反映する
        .onChange(of: selectedMode) { _, newMode in
            viewModel.tunerMode = newMode
        }
        // アンサンブルカウントダウンモーダル
        .fullScreenCover(isPresented: $showEnsembleCountdown) {
            EnsembleCountdownFullScreenModal {
                viewModel.startMonitoring()
            }
        }
        // 設定モーダルを閉じたタイミングで TunerViewModel の設定値を再読み込みする
        .fullScreenCover(isPresented: $isSettingsPresented, onDismiss: {
            viewModel.reloadSettings()
        }) {
            TunerSettingsFullScreenModal()
        }
        .alert("自動停止", isPresented: $viewModel.showSilenceTimeoutAlert) {
            Button("OK") { viewModel.showSilenceTimeoutAlert = false }
        } message: {
            Text(viewModel.silenceTimeoutWasRecording
                ? "30秒間音が検出されなかったため、録音を自動的に停止しました。"
                : "30秒間音が検出されなかったため、計測を自動的に停止しました。"
            )
        }
    }
}

// MARK: - Preview

/// プレビュー専用のダミーUseCase（何もしないスタブ）
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

private struct TunerPreviewWrapper: View {
    @StateObject private var vm = TunerViewModel(useCase: PreviewUseCase())

    var body: some View {
        TunerMainScreen(viewModel: vm)
            .background(Color("AppBackground"))
            .preferredColorScheme(.dark)
            .task {
                vm.currentPitch = 298.0
                vm.isRunning = true
                vm.noteResult = NoteHelper.closestNote(for: 298.0)
                vm.pitchHistory = stride(from: 0.0, to: 5.0, by: 0.1).map { t in
                    let freq = 295.0 + 12.0 * sin(t * 1.5)
                    return PitchSample(time: t, frequency: Float(freq))
                }
            }
    }
}

#Preview("録音中（レ/D4 +8セント）") {
    TunerPreviewWrapper()
}

#Preview("無音・停止中") {
    TunerMainScreen(viewModel: TunerViewModel(useCase: PreviewUseCase()))
        .background(Color("AppBackground"))
        .preferredColorScheme(.dark)
}
