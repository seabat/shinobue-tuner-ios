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

// MARK: - Preview

private let previewRecording = RecordingFile(
    id: UUID(),
    url: URL(fileURLWithPath: "/tmp/2026-02-27_10-00-00.m4a"),
    fileName: "2026-02-27_10-00-00.m4a",
    createdAt: Date(),
    duration: 93,       // 1分33秒
    fileSize: 312_320   // 約305KB
)

#Preview("通常（非選択）") {
    List {
        RecordingRowView(recording: previewRecording, isSelected: false, isPlaying: false)
    }
    .listStyle(.plain)
    .background(Color(red: 0.078, green: 0.078, blue: 0.118))
    .preferredColorScheme(.dark)
}

#Preview("選択中・再生中") {
    List {
        RecordingRowView(recording: previewRecording, isSelected: true, isPlaying: true)
    }
    .listStyle(.plain)
    .background(Color(red: 0.078, green: 0.078, blue: 0.118))
    .preferredColorScheme(.dark)
}

#Preview("選択中・一時停止中") {
    List {
        RecordingRowView(recording: previewRecording, isSelected: true, isPlaying: false)
    }
    .listStyle(.plain)
    .background(Color(red: 0.078, green: 0.078, blue: 0.118))
    .preferredColorScheme(.dark)
}
