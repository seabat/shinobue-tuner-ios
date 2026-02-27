//
//  RecordingListView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  録音ファイル一覧画面

import Combine
import SwiftUI

/// 録音ファイル一覧画面
struct RecordingListView: View {
    @ObservedObject var viewModel: RecordingListViewModel

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

            if viewModel.recordings.isEmpty {
                // 空状態の表示
                VStack(spacing: 16) {
                    Image(systemName: "waveform.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("録音ファイルがありません")
                        .font(.body)
                        .foregroundStyle(.gray)
                    Text("チューナー画面で録音を開始してください")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.6))
                }
            } else {
                VStack(spacing: 0) {
                    List {
                        ForEach(viewModel.recordings) { recording in
                            let isLocked = viewModel.isPlaying
                            let isSelected = viewModel.selectedRecording?.id == recording.id
                            RecordingRowView(
                                recording: recording,
                                isSelected: isSelected,
                                isPlaying: viewModel.isPlaying
                            )
                            // 再生中は選択済み以外のアイテムを半透明にする
                            .opacity(isLocked && !isSelected ? 0.4 : 1.0)
                            .onTapGesture {
                                guard !isLocked else { return }
                                viewModel.selectAndPlay(recording)
                            }
                            .swipeActions(edge: .trailing) {
                                // 再生中はスワイプ削除を非表示にする
                                if !isLocked {
                                    Button(role: .destructive) {
                                        viewModel.deleteRecording(recording)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    // 再生コントロールバー（選択中ファイルがある場合のみ）
                    if viewModel.selectedRecording != nil {
                        PlaybackControlView(viewModel: viewModel)
                    }
                }
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.loadRecordings()
        }
    }
}

// MARK: - Preview

private let previewRecordings: [RecordingFile] = [
    RecordingFile(
        id: UUID(),
        url: URL(fileURLWithPath: "/tmp/2026-02-27_10-00-00.m4a"),
        fileName: "2026-02-27_10-00-00.m4a",
        createdAt: Date(),
        duration: 93,
        fileSize: 312_320
    ),
    RecordingFile(
        id: UUID(),
        url: URL(fileURLWithPath: "/tmp/2026-02-26_21-30-00.m4a"),
        fileName: "2026-02-26_21-30-00.m4a",
        createdAt: Date(),
        duration: 27,
        fileSize: 89_600
    ),
    RecordingFile(
        id: UUID(),
        url: URL(fileURLWithPath: "/tmp/2026-02-25_15-12-34.m4a"),
        fileName: "2026-02-25_15-12-34.m4a",
        createdAt: Date(),
        duration: 185,
        fileSize: 620_800
    )
]

/// プレビュー用スタブ（録音管理）
private final class PreviewManageUseCase: ManageRecordingsUseCaseProtocol {
    let items: [RecordingFile]
    init(_ items: [RecordingFile]) { self.items = items }
    func fetchAll() -> [RecordingFile] { items }
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
}

#Preview("空状態") {
    let vm = RecordingListViewModel(
        manageUseCase: PreviewManageUseCase([]),
        playbackUseCase: PreviewPlaybackUseCase()
    )
    return RecordingListView(viewModel: vm)
        .preferredColorScheme(.dark)
}

#Preview("一覧（選択なし）") {
    let vm = RecordingListViewModel(
        manageUseCase: PreviewManageUseCase(previewRecordings),
        playbackUseCase: PreviewPlaybackUseCase()
    )
    vm.recordings = previewRecordings
    return RecordingListView(viewModel: vm)
        .preferredColorScheme(.dark)
}

#Preview("再生中") {
    let vm = RecordingListViewModel(
        manageUseCase: PreviewManageUseCase(previewRecordings),
        playbackUseCase: PreviewPlaybackUseCase()
    )
    vm.recordings = previewRecordings
    vm.selectedRecording = previewRecordings[0]
    vm.isPlaying = true
    vm.playbackTime = 34
    return RecordingListView(viewModel: vm)
        .preferredColorScheme(.dark)
}
