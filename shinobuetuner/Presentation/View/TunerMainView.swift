//
//  TunerMainView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  チューナーのメイン画面（各サブビューを配置する）

import SwiftUI
import Combine

/// チューナーメインビュー
struct TunerMainView: View {
    @ObservedObject var viewModel: TunerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ─── 音名表示エリア ───
            NoteDisplayView(
                noteResult: viewModel.noteResult,
                currentPitch: viewModel.currentPitch
            )
            .frame(height: 160)
            .padding(.top, 8)

            // ─── チューナーメーター ───
            CentsMeterView(
                cents: viewModel.noteResult?.cents ?? 0,
                isActive: viewModel.currentPitch > 0
            )
            .frame(height: 90)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            // ─── ピッチグラフ（5秒間） ───
            PitchGraphView(
                pitchHistory: viewModel.pitchHistory,
                currentTime: viewModel.currentTime
            )
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // ─── 録音開始/停止ボタン ───
            RecordButton(isRunning: viewModel.isRunning) {
                if viewModel.isRunning {
                    viewModel.stopMonitoring()
                } else {
                    viewModel.startMonitoring()
                }
            }
            .padding(.bottom, 24)
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
