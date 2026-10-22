//
//  PlaybackControlView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  音声一覧画面の下部に表示する再生コントロールバー

import SwiftUI

/// 再生コントロールバー（選択中の音声ファイルがある場合に表示）
struct PlaybackControlView: View {
    /// 再生対象の音声ファイル
    let file: PlaybackFile
    /// 現在の再生位置（秒）
    let playbackTime: TimeInterval
    /// 再生中かどうか（再生/一時停止ボタンのアイコン切替に使用）
    let isPlaying: Bool
    /// シークバーのドラッグ終了時の処理（引数はシーク先の秒数）
    let onSeek: (TimeInterval) -> Void
    /// 再生/一時停止ボタンのタップ時の処理
    let onTogglePlayPause: () -> Void
    /// 停止ボタン（×）のタップ時の処理
    let onStop: () -> Void

    /// ドラッグ操作中かどうか
    @State private var isDragging = false
    /// スライダーの現在位置（再生中は playbackTime に追従し、ドラッグ中はユーザー操作が優先される）
    @State private var sliderValue: TimeInterval = 0

    private var duration: TimeInterval {
        file.duration
    }

    var body: some View {
        VStack(spacing: 10) {
            // シークバー（ドラッグ中はユーザー操作、それ以外は playbackTime に追従）
            Slider(value: $sliderValue, in: 0...max(duration, 1)) { editing in
                isDragging = editing
                if !editing {
                    onSeek(sliderValue)
                }
            }
            .tint(Color.accentColor)
            .padding(.horizontal, 4)
            .onChange(of: playbackTime) { _, newTime in
                // ドラッグ中以外は再生位置に追従してシークバーを動かす
                if !isDragging {
                    sliderValue = newTime
                }
            }

            HStack {
                // 現在の再生位置
                Text(formattedTime(playbackTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color("AssistantText"))
                    .frame(width: 44, alignment: .leading)

                Spacer()

                // 停止ボタン（×）
                Button(action: onStop) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color("InactiveMode"))
                }

                // 再生/一時停止ボタン
                Button(action: onTogglePlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.cyan)
                }

                Spacer()

                // 総再生時間
                Text(formattedTime(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color("AssistantText"))
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(red: 0.10, green: 0.10, blue: 0.16))
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let total = Int(time)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

private let previewPlaybackFile = PlaybackFile(
    url: URL(fileURLWithPath: "/tmp/2026-02-27_10-00-00.m4a"),
    fileName: "2026-02-27_10-00-00.m4a",
    createdAt: Date(),
    duration: 93,
    fileSize: 312_320
)

#Preview("再生中（途中）") {
    PlaybackControlView(
        file: previewPlaybackFile, playbackTime: 34, isPlaying: true,
        onSeek: { _ in }, onTogglePlayPause: {}, onStop: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("一時停止中") {
    PlaybackControlView(
        file: previewPlaybackFile, playbackTime: 34, isPlaying: false,
        onSeek: { _ in }, onTogglePlayPause: {}, onStop: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("再生開始直後") {
    PlaybackControlView(
        file: previewPlaybackFile, playbackTime: 0, isPlaying: true,
        onSeek: { _ in }, onTogglePlayPause: {}, onStop: {}
    )
    .preferredColorScheme(.dark)
}
