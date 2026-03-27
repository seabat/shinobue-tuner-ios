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

    var body: some View {
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

private final class PreviewUseCase: MonitorPitchUseCaseProtocol {
    var pitchPublisher: AnyPublisher<Float, Never> { Empty().eraseToAnyPublisher() }
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
            selectedMode: .constant(.monitoring)
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

        var body: some View {
            ZStack {
                Color(red: 0.078, green: 0.078, blue: 0.118).ignoresSafeArea()
                ControlBarView(viewModel: vm, selectedMode: $mode)
            }
            .preferredColorScheme(.dark)
        }
    }
    return Wrapper()
}
