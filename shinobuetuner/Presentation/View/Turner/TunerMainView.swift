//
//  TunerMainView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  チューナーのメイン画面（各サブビューを配置する）

import SwiftUI
import Combine

/// チューナーメインビューのモード
enum TunerMode: String, CaseIterable {
    case monitoring = "計測"
    case recording  = "録音"
}

/// チューナーメインビュー
struct TunerMainView: View {
    @ObservedObject var viewModel: TunerViewModel
    @ObservedObject private var settings: TunerSettings
    @State private var selectedMode: TunerMode = .monitoring
    @State private var isSettingsPresented: Bool = false

    init(viewModel: TunerViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._settings = ObservedObject(wrappedValue: viewModel.settings)
    }

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
            if settings.showPitchGraph {
                PitchGraphView(
                    pitchHistory: viewModel.pitchHistory,
                    currentTime: viewModel.currentTime
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }

            // ─── 開始/停止ボタン + モード切替 ───
            ZStack {
                // 計測/停止ボタン（中央固定）
                RecordButton(
                    isRunning: viewModel.isRunning,
                    isRecordingMode: selectedMode == .recording
                ) {
                    switch selectedMode {
                    case .monitoring:
                        viewModel.isRunning ? viewModel.stopMonitoring() : viewModel.startMonitoring()
                    case .recording:
                        viewModel.isRunning ? viewModel.stopRecording() : viewModel.startRecording()
                    }
                }

                // 計測/録音 モード切替（右端）
                HStack {
                    Spacer()
                    ModeSwitcher(selectedMode: $selectedMode)
                        .disabled(viewModel.isRunning)
                        .padding(.trailing, 20)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .overlay(alignment: .topTrailing) {
            // ─── 設定ボタン ───
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(.gray.opacity(0.7))
                    .padding(12)
            }
            .disabled(viewModel.isRunning)
        }
        .overlay {
            // ─── チューニング成功エフェクト ───
            TuningCelebrationView(isInTune: viewModel.showTuningCelebration)
        }
        .sheet(isPresented: $isSettingsPresented) {
            TunerSettingsView(settings: viewModel.settings)
                .presentationDetents([.medium, .large])
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

// MARK: - ModeSwitcher

/// 計測/録音モード切替コンポーネント（ボタンの右側に配置）
private struct ModeSwitcher: View {
    @Binding var selectedMode: TunerMode

    var body: some View {
        VStack(spacing: 6) {
            ForEach(TunerMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode == .monitoring ? "mic.circle.fill" : "record.circle")
                            .font(.system(size: 12))
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selectedMode == mode
                        ? (mode == .monitoring ? Color.cyan : Color.orange)
                        : Color(white: 0.4)
                    )
                }
            }
        }
    }
}

// MARK: - Preview

/// プレビュー専用のダミーUseCase（何もしないスタブ）
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

private struct TunerPreviewWrapper: View {
    @StateObject private var vm = TunerViewModel(useCase: PreviewUseCase())

    var body: some View {
        TunerMainView(viewModel: vm)
            .background(Color(red: 0.078, green: 0.078, blue: 0.118))
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
    TunerMainView(viewModel: TunerViewModel(useCase: PreviewUseCase()))
        .background(Color(red: 0.078, green: 0.078, blue: 0.118))
        .preferredColorScheme(.dark)
}
