//
//  ControlBarView.swift
//  shinobuetuner
//
//  開始/停止ボタン + モード切替コンポーネント

import SwiftUI
import Combine

/// 開始/停止ボタン + モード切替コンポーネント
struct ControlBarView: View {
    @ObservedObject var viewModel: TunerViewModel
    @Binding var selectedMode: TunerMode
    /// アンサンブルカウントダウンモーダルの表示フラグ（TunerMainScreen から @Binding で受け取る）
    @Binding var showEnsembleCountdown: Bool

    var body: some View {
        ZStack {
            // 計測/停止ボタン（中央固定）
            RecordButton(
                isRunning: viewModel.isRunning,
                accentColor: accentColor(for: selectedMode),
                startIcon: icon(for: selectedMode)
            ) {
                switch selectedMode {
                case .soloMonitoring:
                    viewModel.isRunning ? viewModel.stopMonitoring() : viewModel.startMonitoring()
                case .ensembleMonitoring:
                    if viewModel.isRunning {
                        viewModel.stopMonitoring()
                    } else {
                        showEnsembleCountdown = true
                    }
                case .recording:
                    viewModel.isRunning ? viewModel.stopRecording() : viewModel.startRecording()
                }
            }

            // モード切替（右端）
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

    private func accentColor(for mode: TunerMode) -> Color {
        switch mode {
        case .soloMonitoring:     return .cyan
        case .ensembleMonitoring: return .green
        case .recording:          return .orange
        }
    }

    private func icon(for mode: TunerMode) -> String {
        switch mode {
        case .soloMonitoring:     return "mic.circle.fill"
        case .ensembleMonitoring: return "person.2.circle.fill"
        case .recording:          return "record.circle"
        }
    }
}

// MARK: - ModeSwitcher

/// 計測(単)/計測(複)/録音 モード切替コンポーネント（ボタンの右側に配置）
private struct ModeSwitcher: View {
    @Binding var selectedMode: TunerMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(TunerMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: icon(for: mode))
                            .font(.system(size: 12))
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selectedMode == mode
                        ? activeColor(for: mode)
                        : Color(white: 0.4)
                    )
                }
            }
        }
    }

    private func icon(for mode: TunerMode) -> String {
        switch mode {
        case .soloMonitoring:     return "mic.circle.fill"
        case .ensembleMonitoring: return "person.2.circle.fill"
        case .recording:          return "record.circle"
        }
    }

    private func activeColor(for mode: TunerMode) -> Color {
        switch mode {
        case .soloMonitoring:     return .cyan
        case .ensembleMonitoring: return .green
        case .recording:          return .orange
        }
    }
}

// MARK: - Preview

private final class PreviewUseCase: MonitorPitchUseCaseProtocol {
    var pitchPublisher: AnyPublisher<Float, Never> { Empty().eraseToAnyPublisher() }
    var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> {
        Empty().eraseToAnyPublisher()
    }
    func start() {}
    func stop() {}
    func requestPermission() async -> Bool { true }
    func startRecording(to url: URL) throws {}
    func stopRecording() {}
}

#Preview("計測モード・停止中") {
    ZStack {
        Color(red: 0.078, green: 0.078, blue: 0.118).ignoresSafeArea()
        ControlBarView(
            viewModel: TunerViewModel(useCase: PreviewUseCase()),
            selectedMode: .constant(.soloMonitoring),
            showEnsembleCountdown: .constant(false)
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("録音モード・動作中") {
    struct Wrapper: View {
        @StateObject private var vm: TunerViewModel = {
            let vm = TunerViewModel(useCase: PreviewUseCase())
            vm.isRunning = true
            return vm
        }()
        @State private var mode: TunerMode = .recording
        @State private var showCountdown = false

        var body: some View {
            ZStack {
                Color(red: 0.078, green: 0.078, blue: 0.118).ignoresSafeArea()
                ControlBarView(viewModel: vm, selectedMode: $mode, showEnsembleCountdown: $showCountdown)
            }
            .preferredColorScheme(.dark)
        }
    }
    return Wrapper()
}
