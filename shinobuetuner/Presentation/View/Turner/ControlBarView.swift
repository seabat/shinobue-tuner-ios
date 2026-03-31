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
                accentColor: modeColor(for: selectedMode),
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

    private func modeColor(for mode: TunerMode) -> Color {
        switch mode {
        case .soloMonitoring:     return Color("SoloMonitoring")
        case .ensembleMonitoring: return Color("EnsembleMonitoring")
        case .recording:          return Color("Recording")
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
                        ? modeColor(for: mode)
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

    private func modeColor(for mode: TunerMode) -> Color {
        switch mode {
        case .soloMonitoring:     return Color("SoloMonitoring")
        case .ensembleMonitoring: return Color("EnsembleMonitoring")
        case .recording:          return Color("Recording")
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

#Preview("ソロ計測モード・停止中") {
    ZStack {
        Color("PreviewBackground").ignoresSafeArea()
        ControlBarView(
            viewModel: TunerViewModel(useCase: PreviewUseCase()),
            selectedMode: .constant(.soloMonitoring),
            showEnsembleCountdown: .constant(false)
        )
        .background(Color("AppBackground"))
    }
    .preferredColorScheme(.light)
}

#Preview("アンサンブル計測モード・停止中") {
    ZStack {
        Color("PreviewBackground").ignoresSafeArea()
        ControlBarView(
            viewModel: TunerViewModel(useCase: PreviewUseCase()),
            selectedMode: .constant(.ensembleMonitoring),
            showEnsembleCountdown: .constant(false)
        )
        .background(Color("AppBackground"))
    }
    .preferredColorScheme(.dark)
}

#Preview("録音モード・停止中") {
    ZStack {
        Color("PreviewBackground").ignoresSafeArea()
        ControlBarView(
            viewModel: TunerViewModel(useCase: PreviewUseCase()),
            selectedMode: .constant(.recording),
            showEnsembleCountdown: .constant(false)
        )
        .background(Color("AppBackground"))
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
                Color("PreviewBackground").ignoresSafeArea() // うすいピンク色
                ControlBarView(viewModel: vm, selectedMode: $mode, showEnsembleCountdown: $showCountdown)
                    .background(Color("AppBackground"))
            }
            .preferredColorScheme(.dark)
        }
    }
    return Wrapper()
}
