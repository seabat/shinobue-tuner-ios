//
//  RenamePlaybackFileUseCase.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/03/28.
//
//  音声ファイルリネームユースケース

import Foundation

/// 音声ファイルリネームユースケースのプロトコル
protocol RenamePlaybackFileUseCaseProtocol {
    /// 指定したファイルの名前を変更し、更新後のファイルを返す
    func callAsFunction(file: PlaybackFile, newName: String) throws -> PlaybackFile
}

/// 音声ファイルリネームユースケースの具体実装
final class RenamePlaybackFileUseCase: RenamePlaybackFileUseCaseProtocol {
    private let repository: any PlaybackFileRepository

    init(repository: any PlaybackFileRepository) {
        self.repository = repository
    }

    func callAsFunction(file: PlaybackFile, newName: String) throws -> PlaybackFile {
        let newURL = try repository.rename(url: file.url, newName: newName)
        return PlaybackFile(
            id: file.id,
            url: newURL,
            fileName: newURL.lastPathComponent,
            createdAt: file.createdAt,
            duration: file.duration,
            fileSize: file.fileSize
        )
    }
}
