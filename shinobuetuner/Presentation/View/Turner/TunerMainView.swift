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
    @State private var selectedMode: TunerMode = .monitoring

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
            PitchGraphView(
                pitchHistory: viewModel.pitchHistory,
                currentTime: viewModel.currentTime
            )
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)

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
        .overlay {
            // ─── チューニング成功エフェクト ───
            TuningCelebrationView(isInTune: viewModel.showTuningCelebration)
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

#Preview("録音中（レ/D4 +8セント）") {
    let vm = TunerViewModel(useCase: PreviewUseCase())
    vm.currentPitch = 298.0
    vm.isRunning = true
    vm.noteResult = NoteHelper.closestNote(for: 298.0)
    vm.pitchHistory = stride(from: 0.0, to: 5.0, by: 0.1).map { t in
        let freq = 295.0 + 12.0 * sin(t * 1.5)
        return PitchSample(time: t, frequency: Float(freq))
    }
    return TunerMainView(viewModel: vm)
        .background(Color(red: 0.078, green: 0.078, blue: 0.118))
        .preferredColorScheme(.dark)
}

#Preview("無音・停止中") {
    let vm = TunerViewModel(useCase: PreviewUseCase())
    return TunerMainView(viewModel: vm)
        .background(Color(red: 0.078, green: 0.078, blue: 0.118))
        .preferredColorScheme(.dark)
}
