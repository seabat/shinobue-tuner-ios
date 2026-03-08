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

    /// リネームアラートの表示対象
    @State private var renamingRecording: RecordingFile? = nil
    /// リネームアラートのテキストフィールド入力値
    @State private var renameText: String = ""
    /// 削除確認アラートの表示対象
    @State private var deletingRecording: RecordingFile? = nil

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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isLocked else { return }
                                viewModel.selectAndPlay(recording)
                            }
                            .swipeActions(edge: .trailing) {
                                // 再生中はスワイプ操作を非表示にする
                                if !isLocked {
                                    Button(role: .destructive) {
                                        deletingRecording = recording
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                    Button {
                                        renameText = recording.fileName
                                            .replacingOccurrences(of: ".m4a", with: "")
                                        renamingRecording = recording
                                    } label: {
                                        Label("名前変更", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                    ShareLink(item: recording.url) {
                                        Label("共有", systemImage: "square.and.arrow.up")
                                    }
                                    .tint(.green)
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
        // 削除確認アラート
        .alert("削除の確認", isPresented: Binding(
            get: { deletingRecording != nil },
            set: { if !$0 { deletingRecording = nil } }
        )) {
            Button("削除", role: .destructive) {
                if let recording = deletingRecording {
                    viewModel.deleteRecording(recording)
                }
                deletingRecording = nil
            }
            Button("キャンセル", role: .cancel) {
                deletingRecording = nil
            }
        } message: {
            if let recording = deletingRecording {
                Text("「\(recording.fileName.replacingOccurrences(of: ".m4a", with: ""))」を削除しますか？\nこの操作は元に戻せません。")
            }
        }
        // リネームアラート
        .alert("名前を変更", isPresented: Binding(
            get: { renamingRecording != nil },
            set: { if !$0 { renamingRecording = nil } }
        )) {
            TextField("ファイル名", text: $renameText)
            Button("変更") {
                if let recording = renamingRecording {
                    viewModel.renameRecording(recording, newName: renameText)
                }
                renamingRecording = nil
            }
            Button("キャンセル", role: .cancel) {
                renamingRecording = nil
            }
        } message: {
            Text("拡張子（.m4a）は自動で付加されます")
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
    func rename(recording: RecordingFile, newName: String) throws -> RecordingFile { recording }
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
