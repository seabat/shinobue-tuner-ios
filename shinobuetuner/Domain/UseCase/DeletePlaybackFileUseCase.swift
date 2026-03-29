//
//  DeletePlaybackFileUseCase.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/03/28.
//
//  音声ファイル削除ユースケース

import Foundation

/// 音声ファイル削除ユースケースのプロトコル
protocol DeletePlaybackFileUseCaseProtocol {
    /// 指定したファイルを削除する
    func callAsFunction(file: PlaybackFile) throws
}

/// 音声ファイル削除ユースケースの具体実装
final class DeletePlaybackFileUseCase: DeletePlaybackFileUseCaseProtocol {
    private let repository: any PlaybackFileRepository

    init(repository: any PlaybackFileRepository) {
        self.repository = repository
    }

    func callAsFunction(file: PlaybackFile) throws {
        try repository.delete(url: file.url)
    }
}
