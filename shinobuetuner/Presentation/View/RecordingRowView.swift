//
//  RecordingRowView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  録音一覧の各行コンポーネント

import SwiftUI

/// 録音一覧の1行を表示するビュー
struct RecordingRowView: View {
    let recording: RecordingFile
    let isSelected: Bool
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 再生状態インジケーター
            Image(systemName: isSelected && isPlaying ? "waveform" : "play.circle")
                .font(.title3)
                .foregroundStyle(isSelected ? .cyan : .gray.opacity(0.5))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                // ファイル名（拡張子を除く）
                Text(recording.fileName.replacingOccurrences(of: ".m4a", with: ""))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    // 録音時間
                    Label(formattedDuration, systemImage: "clock")
                    // ファイルサイズ
                    Label(formattedSize, systemImage: "doc")
                }
                .font(.caption)
                .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(
            isSelected
                ? Color(red: 0.1, green: 0.15, blue: 0.25)
                : Color(red: 0.08, green: 0.08, blue: 0.12)
        )
    }

    private var formattedDuration: String {
        let total = Int(recording.duration)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var formattedSize: String {
        let kb = Double(recording.fileSize) / 1024
        if kb < 1024 {
            return String(format: "%.0f KB", kb)
        } else {
            return String(format: "%.1f MB", kb / 1024)
        }
    }
}
