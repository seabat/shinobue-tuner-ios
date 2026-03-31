//
//  RecordButton.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  録音開始/停止ボタン

import SwiftUI

/// 計測/録音 開始・停止ボタン
struct RecordButton: View {
    let isRunning: Bool
    /// ボタンのアクセントカラー（soloMonitoring: .cyan / ensembleMonitoring: .green / recording: .orange）
    let accentColor: Color
    /// 開始状態のアイコン（ModeSwitcher と同じ SF Symbol 名を渡す）
    let startIcon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isRunning ? "stop.circle.fill" : startIcon)
                    .font(.title2)
                Text(isRunning ? stopLabel : startLabel)
                    .font(.headline)
            }
            .foregroundStyle(isRunning ? .red : accentColor)
            .padding(.horizontal, 36)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(isRunning ? Color.red : accentColor, lineWidth: 2)
            )
        }
        .padding(.horizontal, 24)
    }

    private var startLabel: String {
        accentColor == .orange ? "録音開始" : "計測開始"
    }

    private var stopLabel: String {
        accentColor == .orange ? "録音停止" : "計測停止"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        // ソロ計測モード・停止中
        RecordButton(isRunning: false, accentColor: Color.accentColor, startIcon: "mic.circle.fill") {}
        // ソロ計測モード・計測中
        RecordButton(isRunning: true, accentColor: Color.accentColor, startIcon: "mic.circle.fill") {}
        // アンサンブル計測モード・停止中
        RecordButton(isRunning: false, accentColor: .green, startIcon: "person.2.circle.fill") {}
        // アンサンブル計測モード・計測中
        RecordButton(isRunning: true, accentColor: .green, startIcon: "person.2.circle.fill") {}
        // 録音モード・停止中
        RecordButton(isRunning: false, accentColor: .orange, startIcon: "record.circle") {}
        // 録音モード・録音中
        RecordButton(isRunning: true, accentColor: .orange, startIcon: "record.circle") {}
    }
    .padding(40)
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}
