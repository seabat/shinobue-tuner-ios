//
//  ControlBarView.swift
//  shinobuetuner
//
//  開始/停止ボタン + モード切替コンポーネント

import SwiftUI

/// 開始/停止ボタン + モード切替コンポーネント
struct ControlBarView: View {
    /// 計測・録音の動作中かどうか（ボタン表示の切替とモード切替の無効化に使用）
    let isRunning: Bool
    @Binding var selectedMode: TunerMode
    /// 開始/停止ボタンのタップ時の処理（モードごとの開始・停止は呼び出し元で決める）
    let onPrimaryAction: () -> Void

    var body: some View {
        // 計測/停止ボタンとモード切替を同じ行に並べる（ZStackでの重ね配置だと
        // ローカライズでラベル文字数が増えた際にモード切替と衝突するため、
        // HStack + maxWidth: .infinity でボタン側に余白を吸収させる）
        HStack(spacing: 12) {
            TunerModeButton(
                isRunning: isRunning,
                accentColor: modeColor(for: selectedMode),
                startIcon: icon(for: selectedMode),
                isRecording: selectedMode == .recording,
                action: onPrimaryAction
            )

            ModeSwitcher(selectedMode: $selectedMode)
                .disabled(isRunning)
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
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
/// タップすると現在のモードをポップオーバーのドラムロール（.wheel ピッカー）で切替できる
private struct ModeSwitcher: View {
    @Binding var selectedMode: TunerMode
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon(for: selectedMode))
                    .font(.system(size: 15))
                Text(selectedMode.displayName)
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(modeColor(for: selectedMode))
        }
        .popover(isPresented: $showPicker) {
            Picker("", selection: $selectedMode) {
                ForEach(TunerMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 160, height: 180)
            .presentationCompactAdaptation(.popover)
            .onChange(of: selectedMode) { _, _ in
                // ホイールで選択したら自動的にポップオーバーを閉じる
                showPicker = false
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

#Preview("ソロ計測モード・停止中") {
    ZStack {
        Color("PreviewBackground").ignoresSafeArea()
        ControlBarView(isRunning: false, selectedMode: .constant(.soloMonitoring)) {}
            .background(Color("AppBackground"))
    }
    .preferredColorScheme(.light)
}

#Preview("アンサンブル計測モード・停止中") {
    ZStack {
        Color("PreviewBackground").ignoresSafeArea()
        ControlBarView(isRunning: false, selectedMode: .constant(.ensembleMonitoring)) {}
            .background(Color("AppBackground"))
    }
    .preferredColorScheme(.dark)
}

#Preview("録音モード・停止中") {
    ZStack {
        Color("PreviewBackground").ignoresSafeArea()
        ControlBarView(isRunning: false, selectedMode: .constant(.recording)) {}
            .background(Color("AppBackground"))
    }
    .preferredColorScheme(.dark)
}

#Preview("録音モード・動作中") {
    @Previewable @State var isRunning = true
    @Previewable @State var mode: TunerMode = .recording

    ZStack {
        Color("PreviewBackground").ignoresSafeArea() // うすいピンク色
        ControlBarView(isRunning: isRunning, selectedMode: $mode) {
            isRunning.toggle()
        }
        .background(Color("AppBackground"))
    }
    .preferredColorScheme(.dark)
}
