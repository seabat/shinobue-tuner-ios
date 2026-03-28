//
//  FetchPlaybackFilesUseCase.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/03/28.
//
//  音声ファイル一覧取得ユースケース

import Foundation

/// 音声ファイル一覧取得ユースケースのプロトコル
protocol FetchPlaybackFilesUseCaseProtocol {
    /// 保存済みファイルを新しい順に返す
    func callAsFunction() -> [PlaybackFile]
}

/// 音声ファイル一覧取得ユースケースの具体実装
final class FetchPlaybackFilesUseCase: FetchPlaybackFilesUseCaseProtocol {
    private let repository: any PlaybackFileRepository

    init(repository: any PlaybackFileRepository) {
        self.repository = repository
    }

    func callAsFunction() -> [PlaybackFile] {
        repository.fetchAll()
    }
}
