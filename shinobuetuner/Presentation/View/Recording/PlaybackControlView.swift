//
//  PlaybackControlView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  録音一覧画面の下部に表示する再生コントロールバー

import Combine
import SwiftUI

/// 再生コントロールバー（選択中の録音ファイルがある場合に表示）
struct PlaybackControlView: View {
    @ObservedObject var viewModel: RecordingListViewModel

    /// ドラッグ操作中かどうか
    @State private var isDragging = false
    /// スライダーの現在位置（再生中は playbackTime に追従し、ドラッグ中はユーザー操作が優先される）
    @State private var sliderValue: TimeInterval = 0

    private var duration: TimeInterval {
        viewModel.selectedRecording?.duration ?? 1
    }

    var body: some View {
        VStack(spacing: 10) {
            // シークバー（ドラッグ中はユーザー操作、それ以外は playbackTime に追従）
            Slider(value: $sliderValue, in: 0...max(duration, 1)) { editing in
                isDragging = editing
                if !editing {
                    viewModel.seek(to: sliderValue)
                }
            }
            .tint(.cyan)
            .padding(.horizontal, 4)
            .onChange(of: viewModel.playbackTime) { _, newTime in
                // ドラッグ中以外は再生位置に追従してシークバーを動かす
                if !isDragging {
                    sliderValue = newTime
                }
            }

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

// MARK: - Preview

private let previewRecording = RecordingFile(
    id: UUID(),
    url: URL(fileURLWithPath: "/tmp/2026-02-27_10-00-00.m4a"),
    fileName: "2026-02-27_10-00-00.m4a",
    createdAt: Date(),
    duration: 93,
    fileSize: 312_320
)

/// プレビュー用スタブ（録音管理）
private final class PreviewManageUseCase: ManageRecordingsUseCaseProtocol {
    func fetchAll() -> [RecordingFile] { [] }
    func delete(recording: RecordingFile) throws {}
}

/// プレビュー用スタブ（再生）
private final class PreviewPlaybackUseCase: PlaybackUseCaseProtocol {
    var playbackTimePublisher: AnyPublisher<TimeInterval, Never> {
        Just(0).eraseToAnyPublisher()
    }
    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
    func play(recording: RecordingFile) throws {}
    func pause() {}
    func resume() {}
    func stop() {}
    func seek(to time: TimeInterval) {}
}

#Preview("再生中（途中）") {
    let vm = RecordingListViewModel(
        manageUseCase: PreviewManageUseCase(),
        playbackUseCase: PreviewPlaybackUseCase()
    )
    vm.selectedRecording = previewRecording
    vm.isPlaying = true
    vm.playbackTime = 34
    return PlaybackControlView(viewModel: vm)
        .preferredColorScheme(.dark)
}

#Preview("一時停止中") {
    let vm = RecordingListViewModel(
        manageUseCase: PreviewManageUseCase(),
        playbackUseCase: PreviewPlaybackUseCase()
    )
    vm.selectedRecording = previewRecording
    vm.isPlaying = false
    vm.playbackTime = 34
    return PlaybackControlView(viewModel: vm)
        .preferredColorScheme(.dark)
}

#Preview("再生開始直後") {
    let vm = RecordingListViewModel(
        manageUseCase: PreviewManageUseCase(),
        playbackUseCase: PreviewPlaybackUseCase()
    )
    vm.selectedRecording = previewRecording
    vm.isPlaying = true
    vm.playbackTime = 0
    return PlaybackControlView(viewModel: vm)
        .preferredColorScheme(.dark)
}
