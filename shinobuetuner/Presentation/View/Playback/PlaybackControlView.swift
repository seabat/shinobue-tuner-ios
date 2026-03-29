//
//  PlaybackControlView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  音声一覧画面の下部に表示する再生コントロールバー

import Combine
import SwiftUI

/// 再生コントロールバー（選択中の音声ファイルがある場合に表示）
struct PlaybackControlView: View {
    @ObservedObject var viewModel: PlaybackListViewModel

    /// ドラッグ操作中かどうか
    @State private var isDragging = false
    /// スライダーの現在位置（再生中は playbackTime に追従し、ドラッグ中はユーザー操作が優先される）
    @State private var sliderValue: TimeInterval = 0

    private var duration: TimeInterval {
        viewModel.selectedPlaybackFile?.duration ?? 1
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

private let previewPlaybackFile = PlaybackFile(
    url: URL(fileURLWithPath: "/tmp/2026-02-27_10-00-00.m4a"),
    fileName: "2026-02-27_10-00-00.m4a",
    createdAt: Date(),
    duration: 93,
    fileSize: 312_320
)

/// プレビュー用スタブ（一覧取得）
private final class PreviewFetchUseCase: FetchPlaybackFilesUseCaseProtocol {
    func callAsFunction() -> [PlaybackFile] { [] }
}

/// プレビュー用スタブ（削除）
private final class PreviewDeleteUseCase: DeletePlaybackFileUseCaseProtocol {
    func callAsFunction(file: PlaybackFile) throws {}
}

/// プレビュー用スタブ（リネーム）
private final class PreviewRenameUseCase: RenamePlaybackFileUseCaseProtocol {
    func callAsFunction(file: PlaybackFile, newName: String) throws -> PlaybackFile { file }
}

/// プレビュー用スタブ（頭出し）
private final class PreviewTrimUseCase: TrimLeadingSilenceUseCaseProtocol {
    func callAsFunction(file: PlaybackFile) async throws {}
}

/// プレビュー用スタブ（再生）
private final class PreviewPlaybackUseCase: PlaybackUseCaseProtocol {
    var playbackTimePublisher: AnyPublisher<TimeInterval, Never> {
        Just(0).eraseToAnyPublisher()
    }
    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
    func play(file: PlaybackFile) throws {}
    func pause() {}
    func resume() {}
    func stop() {}
    func seek(to time: TimeInterval) {}
}

@MainActor
private func makePreviewVM(
    selected: PlaybackFile? = nil,
    playing: Bool = false,
    time: TimeInterval = 0
) -> PlaybackListViewModel {
    let vm = PlaybackListViewModel(
        fetchUseCase: PreviewFetchUseCase(),
        deleteUseCase: PreviewDeleteUseCase(),
        renameUseCase: PreviewRenameUseCase(),
        trimUseCase: PreviewTrimUseCase(),
        playbackUseCase: PreviewPlaybackUseCase(),
        fetchSettingsUseCase: FetchPlaybackSettingsUseCase(repository: PlaybackSettingsRepositoryImpl()),
        importUseCase: ImportPlaybackFileUseCase(repository: PlaybackFileRepositoryImpl())
    )
    vm.selectedPlaybackFile = selected
    vm.isPlaying = playing
    vm.playbackTime = time
    return vm
}

#Preview("再生中（途中）") {
    PlaybackControlView(viewModel: makePreviewVM(
        selected: previewPlaybackFile,
        playing: true,
        time: 34
    ))
    .preferredColorScheme(.dark)
}

#Preview("一時停止中") {
    PlaybackControlView(viewModel: makePreviewVM(
        selected: previewPlaybackFile,
        playing: false,
        time: 34
    ))
    .preferredColorScheme(.dark)
}

#Preview("再生開始直後") {
    PlaybackControlView(viewModel: makePreviewVM(
        selected: previewPlaybackFile,
        playing: true,
        time: 0
    ))
    .preferredColorScheme(.dark)
}
