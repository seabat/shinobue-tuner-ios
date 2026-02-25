//
//  RecordButton.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  録音開始/停止ボタン

import SwiftUI

/// 録音開始/停止ボタン
struct RecordButton: View {
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isRunning ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title2)
                Text(isRunning ? "録音停止" : "録音開始")
                    .font(.headline)
            }
            .foregroundStyle(isRunning ? .red : .cyan)
            .padding(.horizontal, 36)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(isRunning ? Color.red : Color.cyan, lineWidth: 2)
            )
        }
        .padding(.horizontal, 24)
    }
}
