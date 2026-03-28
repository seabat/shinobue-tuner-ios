//
//  PlaybackListViewModel.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  音声一覧画面の状態管理ViewModel

import Combine
import Foundation

/// 音声一覧画面の状態を管理するViewModel
@MainActor
final class PlaybackListViewModel: ObservableObject {
    // MARK: - 公開状態

    /// 音声ファイル一覧（新しい順）
    @Published var playbackFiles: [PlaybackFile] = []
    /// 現在選択・再生中の音声ファイル
    @Published var selectedPlaybackFile: PlaybackFile? = nil
    /// 再生中かどうか
    @Published var isPlaying: Bool = false
    /// 現在の再生位置（秒）
    @Published var playbackTime: TimeInterval = 0
    /// エラーメッセージ
    @Published var errorMessage: String? = nil

    // MARK: - 内部

    private let fetchUseCase: any FetchPlaybackFilesUseCaseProtocol
    private let deleteUseCase: any DeletePlaybackFileUseCaseProtocol
    private let renameUseCase: any RenamePlaybackFileUseCaseProtocol
    private let playbackUseCase: any PlaybackUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    /// デフォルトの依存性を使って初期化（本番用）
    convenience init() {
        let repository = PlaybackFileRepositoryImpl()
        self.init(
            fetchUseCase: FetchPlaybackFilesUseCase(repository: repository),
            deleteUseCase: DeletePlaybackFileUseCase(repository: repository),
            renameUseCase: RenamePlaybackFileUseCase(repository: repository),
            playbackUseCase: PlaybackUseCase(repository: PlaybackRepositoryImpl())
        )
    }

    /// テスト時にモックを注入できる初期化
    init(
        fetchUseCase: any FetchPlaybackFilesUseCaseProtocol,
        deleteUseCase: any DeletePlaybackFileUseCaseProtocol,
        renameUseCase: any RenamePlaybackFileUseCaseProtocol,
        playbackUseCase: any PlaybackUseCaseProtocol
    ) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
        self.renameUseCase = renameUseCase
        self.playbackUseCase = playbackUseCase
        subscribePlayback()
    }

    // MARK: - 操作

    /// 音声ファイル一覧を読み込む
    func loadPlaybackFiles() {
        playbackFiles = fetchUseCase()
    }

    /// 音声ファイルを削除する
    func deletePlaybackFile(_ playbackFile: PlaybackFile) {
        do {
            try deleteUseCase(file: playbackFile)
            if selectedPlaybackFile?.id == playbackFile.id {
                stopPlayback()
            }
            loadPlaybackFiles()
        } catch {
            errorMessage = "削除に失敗しました: \(error.localizedDescription)"
        }
    }

    /// 音声ファイルの名前を変更する
    func renamePlaybackFile(_ playbackFile: PlaybackFile, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            let renamed = try renameUseCase(file: playbackFile, newName: trimmed)
            // 再生中のファイルだった場合は選択中URLを更新
            if selectedPlaybackFile?.id == playbackFile.id {
                selectedPlaybackFile = renamed
            }
            loadPlaybackFiles()
        } catch {
            errorMessage = "名前の変更に失敗しました: \(error.localizedDescription)"
        }
    }

    /// 音声ファイルを選択して再生する
    func selectAndPlay(_ playbackFile: PlaybackFile) {
        do {
            playbackTime = 0
            selectedPlaybackFile = playbackFile
            try playbackUseCase.play(file: playbackFile)
        } catch {
            errorMessage = "再生に失敗しました: \(error.localizedDescription)"
        }
    }

    /// 再生/一時停止を切り替える
    func togglePlayPause() {
        if isPlaying {
            playbackUseCase.pause()
        } else {
            playbackUseCase.resume()
        }
    }

    /// 再生を停止して選択を解除する
    func stopPlayback() {
        playbackUseCase.stop()
        selectedPlaybackFile = nil
    }

    /// 指定した位置（秒）にシークする
    func seek(to time: TimeInterval) {
        playbackUseCase.seek(to: time)
    }

    // MARK: - 内部処理

    /// 再生状態・再生位置のパブリッシャーを購読する
    private func subscribePlayback() {
        playbackUseCase.isPlayingPublisher
            .sink { [weak self] playing in
                self?.isPlaying = playing
            }
            .store(in: &cancellables)

        playbackUseCase.playbackTimePublisher
            .sink { [weak self] time in
                self?.playbackTime = time
            }
            .store(in: &cancellables)
    }
}
