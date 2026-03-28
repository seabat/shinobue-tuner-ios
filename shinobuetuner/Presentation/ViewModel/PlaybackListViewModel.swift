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
    /// 頭出し処理中かどうか
    @Published var isTrimming: Bool = false

    // MARK: - 内部

    /// 音声ファイルの設定値（読み取り専用・保存は PlaybackSettingsViewModel が担う）
    @Published var playbackSettings: PlaybackSettings

    private let fetchUseCase: any FetchPlaybackFilesUseCaseProtocol
    private let deleteUseCase: any DeletePlaybackFileUseCaseProtocol
    private let renameUseCase: any RenamePlaybackFileUseCaseProtocol
    private let playbackUseCase: any PlaybackUseCaseProtocol
    private let trimUseCase: any TrimLeadingSilenceUseCaseProtocol
    private let importUseCase: any ImportPlaybackFileUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    /// デフォルトの依存性を使って初期化（本番用）
    convenience init() {
        let fileRepository = PlaybackFileRepositoryImpl()
        let settingsRepository = PlaybackSettingsRepositoryImpl()
        self.init(
            fetchUseCase: FetchPlaybackFilesUseCase(repository: fileRepository),
            deleteUseCase: DeletePlaybackFileUseCase(repository: fileRepository),
            renameUseCase: RenamePlaybackFileUseCase(repository: fileRepository),
            trimUseCase: TrimLeadingSilenceUseCase(repository: fileRepository, settingsRepository: settingsRepository),
            playbackUseCase: PlaybackUseCase(repository: PlaybackRepositoryImpl()),
            fetchSettingsUseCase: FetchPlaybackSettingsUseCase(repository: settingsRepository),
            importUseCase: ImportPlaybackFileUseCase(repository: fileRepository)
        )
    }

    /// テスト時にモックを注入できる初期化
    init(
        fetchUseCase: any FetchPlaybackFilesUseCaseProtocol,
        deleteUseCase: any DeletePlaybackFileUseCaseProtocol,
        renameUseCase: any RenamePlaybackFileUseCaseProtocol,
        trimUseCase: any TrimLeadingSilenceUseCaseProtocol,
        playbackUseCase: any PlaybackUseCaseProtocol,
        fetchSettingsUseCase: any FetchPlaybackSettingsUseCaseProtocol,
        importUseCase: any ImportPlaybackFileUseCaseProtocol
    ) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
        self.renameUseCase = renameUseCase
        self.trimUseCase = trimUseCase
        self.playbackUseCase = playbackUseCase
        self.importUseCase = importUseCase
        _playbackSettings = Published(initialValue: fetchSettingsUseCase())
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

    /// 音声ファイルの先頭の無音区間を除去する
    func trimLeadingSilence(_ playbackFile: PlaybackFile) {
        isTrimming = true
        Task {
            defer { isTrimming = false }
            do {
                try await trimUseCase(file: playbackFile)
                loadPlaybackFiles()
            } catch {
                errorMessage = "頭出しに失敗しました: \(error.localizedDescription)"
            }
        }
    }

    /// 指定した位置（秒）にシークする
    func seek(to time: TimeInterval) {
        playbackUseCase.seek(to: time)
    }

    /// 他アプリから共有された音声ファイルをインポートしてプレイリストに追加する
    func importFile(from url: URL) {
        do {
            _ = try importUseCase(from: url)
            loadPlaybackFiles()
        } catch {
            errorMessage = "ファイルのインポートに失敗しました: \(error.localizedDescription)"
        }
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
