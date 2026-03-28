//
//  PlaybackListScreen.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  音声ファイル一覧画面

import Combine
import SwiftUI

/// 音声ファイル一覧画面
struct PlaybackListScreen: View {
    @ObservedObject var viewModel: PlaybackListViewModel

    /// リネームアラートの表示対象
    @State private var renamingFile: PlaybackFile? = nil
    /// リネームアラートのテキストフィールド入力値
    @State private var renameText: String = ""
    /// 削除確認アラートの表示対象
    @State private var deletingFile: PlaybackFile? = nil
    /// 設定モーダルの表示フラグ
    @State private var isSettingsPresented: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ─── タイトルバー ───
                Text("プレイリスト")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                if viewModel.playbackFiles.isEmpty {
                    // 空状態の表示
                    VStack(spacing: 16) {
                        Image(systemName: "waveform.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray.opacity(0.4))
                        Text("音声ファイルがありません")
                            .font(.body)
                            .foregroundStyle(.gray)
                        Text("チューナー画面で録音してください")
                            .font(.caption)
                            .foregroundStyle(.gray.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        List {
                            ForEach(viewModel.playbackFiles) { playbackFile in
                                let isLocked = viewModel.isPlaying
                                let isSelected = viewModel.selectedPlaybackFile?.id == playbackFile.id
                                PlaybackRowView(
                                    playbackFile: playbackFile,
                                    isSelected: isSelected,
                                    isPlaying: viewModel.isPlaying
                                )
                                // 再生中は選択済み以外のアイテムを半透明にする
                                .opacity(isLocked && !isSelected ? 0.4 : 1.0)
                                // セパレーターの開始位置を左端（0）に固定（デフォルトはアイコン分インデントされる）
                                .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard !isLocked else { return }
                                    viewModel.selectAndPlay(playbackFile)
                                }
                                // ボタンのサイズは swipeActions コンテナが自動決定（明示的な指定不要）
                                .swipeActions(edge: .trailing) {
                                    // 再生中はスワイプ操作を非表示にする
                                    if !isLocked {
                                        Button(role: .destructive) {
                                            deletingFile = playbackFile
                                        } label: {
                                            Label("削除", systemImage: "trash")
                                        }
                                        Button {
                                            renameText = playbackFile.fileName
                                                .replacingOccurrences(of: ".m4a", with: "")
                                            renamingFile = playbackFile
                                        } label: {
                                            Label("名前変更", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                        ShareLink(item: playbackFile.url) {
                                            Label("共有", systemImage: "square.and.arrow.up")
                                        }
                                        .tint(.green)
                                        Button {
                                            viewModel.trimLeadingSilence(playbackFile)
                                        } label: {
                                            Label("頭出し", systemImage: "scissors")
                                        }
                                        .tint(.orange)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)

                        // 再生コントロールバー（選択中ファイルがある場合のみ）
                        if viewModel.selectedPlaybackFile != nil {
                            PlaybackControlView(viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            // ─── 設定ボタン ───
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(.gray.opacity(0.7))
                    .padding(12)
            }
        }
        // 設定モーダルを閉じたタイミングで設定値を再読み込みし、並び替えを反映する
        .fullScreenCover(isPresented: $isSettingsPresented, onDismiss: {
            viewModel.reloadSettingsAndRefresh()
        }) {
            PlaybackSettingsFullScreenModal()
        }
        // 削除確認アラート
        .alert("削除の確認", isPresented: Binding(
            get: { deletingFile != nil },
            set: { if !$0 { deletingFile = nil } }
        )) {
            Button("削除", role: .destructive) {
                if let playbackFile = deletingFile {
                    viewModel.deletePlaybackFile(playbackFile)
                }
                deletingFile = nil
            }
            Button("キャンセル", role: .cancel) {
                deletingFile = nil
            }
        } message: {
            if let file = deletingFile {
                Text("「\(file.fileName.replacingOccurrences(of: ".m4a", with: ""))」を削除しますか？\nこの操作は元に戻せません。")
            }
        }
        // リネームアラート
        .alert("名前を変更", isPresented: Binding(
            get: { renamingFile != nil },
            set: { if !$0 { renamingFile = nil } }
        )) {
            TextField("ファイル名", text: $renameText)
            Button("変更") {
                if let file = renamingFile {
                    viewModel.renamePlaybackFile(file, newName: renameText)
                }
                renamingFile = nil
            }
            Button("キャンセル", role: .cancel) {
                renamingFile = nil
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
            viewModel.loadPlaybackFiles()
        }
    }
}

// MARK: - Preview

private let previewPlaybackFiles: [PlaybackFile] = [
    PlaybackFile(
        url: URL(fileURLWithPath: "/tmp/2026-02-27_10-00-00.m4a"),
        fileName: "2026-02-27_10-00-00.m4a",
        createdAt: Date(),
        duration: 93,
        fileSize: 312_320
    ),
    PlaybackFile(
        url: URL(fileURLWithPath: "/tmp/2026-02-26_21-30-00.m4a"),
        fileName: "2026-02-26_21-30-00.m4a",
        createdAt: Date(),
        duration: 27,
        fileSize: 89_600
    ),
    PlaybackFile(
        url: URL(fileURLWithPath: "/tmp/2026-02-25_15-12-34.m4a"),
        fileName: "2026-02-25_15-12-34.m4a",
        createdAt: Date(),
        duration: 185,
        fileSize: 620_800
    )
]

/// プレビュー用スタブ（一覧取得）
private final class PreviewFetchUseCase: FetchPlaybackFilesUseCaseProtocol {
    let items: [PlaybackFile]
    init(_ items: [PlaybackFile]) { self.items = items }
    func callAsFunction() -> [PlaybackFile] { items }
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
    files: [PlaybackFile],
    selected: PlaybackFile? = nil,
    playing: Bool = false,
    time: TimeInterval = 0
) -> PlaybackListViewModel {
    let settingsRepository = PlaybackSettingsRepositoryImpl()
    let vm = PlaybackListViewModel(
        fetchUseCase: PreviewFetchUseCase(files),
        deleteUseCase: PreviewDeleteUseCase(),
        renameUseCase: PreviewRenameUseCase(),
        trimUseCase: PreviewTrimUseCase(),
        playbackUseCase: PreviewPlaybackUseCase(),
        fetchSettingsUseCase: FetchPlaybackSettingsUseCase(repository: settingsRepository),
        importUseCase: ImportPlaybackFileUseCase(repository: PlaybackFileRepositoryImpl())
    )
    vm.playbackFiles = files
    vm.selectedPlaybackFile = selected
    vm.isPlaying = playing
    vm.playbackTime = time
    return vm
}

#Preview("空状態") {
    PlaybackListScreen(viewModel: makePreviewVM(files: []))
        .preferredColorScheme(.dark)
}

#Preview("一覧（選択なし）") {
    PlaybackListScreen(viewModel: makePreviewVM(files: previewPlaybackFiles))
        .preferredColorScheme(.dark)
}

#Preview("再生中") {
    PlaybackListScreen(viewModel: makePreviewVM(
        files: previewPlaybackFiles,
        selected: previewPlaybackFiles[0],
        playing: true,
        time: 34
    ))
    .preferredColorScheme(.dark)
}
