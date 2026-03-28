//
//  ImportPlaybackFileUseCase.swift
//  shinobuetuner
//
//  他アプリから共有された音声ファイルをプレイリストにインポートするユースケース

import Foundation

/// 音声ファイルインポートユースケースのプロトコル
protocol ImportPlaybackFileUseCaseProtocol {
    /// 外部URLの音声ファイルを Documents にコピーし PlaybackFile を返す
    func callAsFunction(from url: URL) throws -> PlaybackFile
}

/// 音声ファイルインポートユースケースの具体実装
final class ImportPlaybackFileUseCase: ImportPlaybackFileUseCaseProtocol {
    private let repository: any PlaybackFileRepository

    init(repository: any PlaybackFileRepository) {
        self.repository = repository
    }

    func callAsFunction(from url: URL) throws -> PlaybackFile {
        try repository.importFile(from: url)
    }
}
