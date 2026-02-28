//
//  RecordingListViewModel.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  録音一覧画面の状態管理ViewModel

import Combine
import Foundation

/// 録音一覧画面の状態を管理するViewModel
@MainActor
final class RecordingListViewModel: ObservableObject {
    // MARK: - 公開状態

    /// 録音ファイル一覧（新しい順）
    @Published var recordings: [RecordingFile] = []
    /// 現在選択・再生中の録音ファイル
    @Published var selectedRecording: RecordingFile? = nil
    /// 再生中かどうか
    @Published var isPlaying: Bool = false
    /// 現在の再生位置（秒）
    @Published var playbackTime: TimeInterval = 0
    /// エラーメッセージ
    @Published var errorMessage: String? = nil

    // MARK: - 内部

    private let manageUseCase: any ManageRecordingsUseCaseProtocol
    private let playbackUseCase: any PlaybackUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    /// デフォルトの依存性を使って初期化（本番用）
    convenience init() {
        self.init(
            manageUseCase: ManageRecordingsUseCase(repository: RecordingRepositoryImpl()),
            playbackUseCase: PlaybackUseCase(repository: PlaybackRepositoryImpl())
        )
    }

    /// テスト時にモックを注入できる初期化
    init(
        manageUseCase: any ManageRecordingsUseCaseProtocol,
        playbackUseCase: any PlaybackUseCaseProtocol
    ) {
        self.manageUseCase = manageUseCase
        self.playbackUseCase = playbackUseCase
        subscribePlayback()
    }

    // MARK: - 操作

    /// 録音ファイル一覧を読み込む
    func loadRecordings() {
        recordings = manageUseCase.fetchAll()
    }

    /// 録音ファイルを削除する
    func deleteRecording(_ recording: RecordingFile) {
        do {
            try manageUseCase.delete(recording: recording)
            if selectedRecording?.id == recording.id {
                stopPlayback()
            }
            loadRecordings()
        } catch {
            errorMessage = "削除に失敗しました: \(error.localizedDescription)"
        }
    }

    /// 録音ファイルを選択して再生する
    func selectAndPlay(_ recording: RecordingFile) {
        do {
            playbackTime = 0
            selectedRecording = recording
            try playbackUseCase.play(recording: recording)
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
        selectedRecording = nil
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
