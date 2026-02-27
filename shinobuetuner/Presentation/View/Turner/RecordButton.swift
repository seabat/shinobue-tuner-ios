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
    /// true: 録音モード / false: 計測モード
    let isRecordingMode: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isRunning ? "stop.circle.fill" : startIcon)
                    .font(.title2)
                Text(isRunning ? stopLabel : startLabel)
                    .font(.headline)
            }
            .foregroundStyle(isRunning ? .red : activeColor)
            .padding(.horizontal, 36)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(isRunning ? Color.red : activeColor, lineWidth: 2)
            )
        }
        .padding(.horizontal, 24)
    }

    /// 開始状態のアクセントカラー（計測: シアン / 録音: オレンジ）
    private var activeColor: Color {
        isRecordingMode ? .orange : .cyan
    }

    private var startIcon: String {
        isRecordingMode ? "record.circle" : "mic.circle.fill"
    }

    private var startLabel: String {
        isRecordingMode ? "録音開始" : "計測開始"
    }

    private var stopLabel: String {
        isRecordingMode ? "録音停止" : "計測停止"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        // 計測モード・停止中
        RecordButton(isRunning: false, isRecordingMode: false) {}
        // 計測モード・計測中
        RecordButton(isRunning: true, isRecordingMode: false) {}
        // 録音モード・停止中
        RecordButton(isRunning: false, isRecordingMode: true) {}
        // 録音モード・録音中
        RecordButton(isRunning: true, isRecordingMode: true) {}
    }
    .padding(40)
    .background(Color(red: 0.078, green: 0.078, blue: 0.118))
    .preferredColorScheme(.dark)
}
