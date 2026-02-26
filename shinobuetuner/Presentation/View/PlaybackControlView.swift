//
//  PlaybackControlView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  録音一覧画面の下部に表示する再生コントロールバー

import SwiftUI

/// 再生コントロールバー（選択中の録音ファイルがある場合に表示）
struct PlaybackControlView: View {
    @ObservedObject var viewModel: RecordingListViewModel

    private var duration: TimeInterval {
        viewModel.selectedRecording?.duration ?? 1
    }

    var body: some View {
        VStack(spacing: 10) {
            // シークバー
            Slider(
                value: Binding(
                    get: { viewModel.playbackTime },
                    set: { _ in }  // シークは今後の拡張として保留
                ),
                in: 0...max(duration, 1)
            )
            .tint(.cyan)
            .padding(.horizontal, 4)

            HStack {
                // 現在の再生位置
                Text(formattedTime(viewModel.playbackTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.gray)
                    .frame(width: 44, alignment: .leading)

                Spacer()

                // 停止ボタン（×）
                Button {
                    viewModel.stopPlayback()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }

                // 再生/一時停止ボタン
                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.cyan)
                }

                Spacer()

                // 総再生時間
                Text(formattedTime(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.gray)
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
