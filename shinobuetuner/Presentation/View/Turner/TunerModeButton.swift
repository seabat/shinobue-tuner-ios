//
//  TunerModeButton.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  計測/録音 開始・停止ボタン

import SwiftUI

/// 計測/録音 開始・停止ボタン
struct TunerModeButton: View {
    let isRunning: Bool
    /// ボタンのアクセントカラー（soloMonitoring: SoloMonitoring / ensembleMonitoring: EnsembleMonitoring / recording: Recording）
    let accentColor: Color
    /// 開始状態のアイコン（ModeSwitcher と同じ SF Symbol 名を渡す）
    let startIcon: String
    /// 録音モードかどうか（ラベルを「録音開始/停止」にするか「計測開始/停止」にするかの判定に使用）
    var isRecording: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isRunning ? "stop.circle.fill" : startIcon)
                    .font(.title2)
                Text(isRunning ? stopLabel : startLabel)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isRunning ? .red : accentColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(isRunning ? Color.red : accentColor, lineWidth: 2)
            )
        }
    }

    private var startLabel: LocalizedStringResource {
        isRecording ? "録音開始" : "計測開始"
    }

    private var stopLabel: LocalizedStringResource {
        isRecording ? "録音停止" : "計測停止"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        // ソロ計測モード・停止中
        TunerModeButton(isRunning: false, accentColor: Color.accentColor, startIcon: "mic.circle.fill") {}
        // ソロ計測モード・計測中
        TunerModeButton(isRunning: true, accentColor: Color.accentColor, startIcon: "mic.circle.fill") {}
        // アンサンブル計測モード・停止中
        TunerModeButton(isRunning: false, accentColor: .green, startIcon: "person.2.circle.fill") {}
        // アンサンブル計測モード・計測中
        TunerModeButton(isRunning: true, accentColor: .green, startIcon: "person.2.circle.fill") {}
        // 録音モード・停止中
        TunerModeButton(isRunning: false, accentColor: .orange, startIcon: "record.circle", isRecording: true) {}
        // 録音モード・録音中
        TunerModeButton(isRunning: true, accentColor: .orange, startIcon: "record.circle", isRecording: true) {}
    }
    .padding(40)
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}
