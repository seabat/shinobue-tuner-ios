//
//  ManageRecordingsUseCase.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  録音ファイルの一覧取得・削除ユースケース

import Foundation

/// 録音ファイル管理ユースケースのプロトコル
protocol ManageRecordingsUseCaseProtocol {
    /// 保存済み録音ファイルを新しい順に返す
    func fetchAll() -> [RecordingFile]

    /// 録音ファイルを削除する
    func delete(recording: RecordingFile) throws
}

/// 録音ファイル管理ユースケースの具体実装
final class ManageRecordingsUseCase: ManageRecordingsUseCaseProtocol {
    private let repository: any RecordingRepository

    init(repository: any RecordingRepository) {
        self.repository = repository
    }

    func fetchAll() -> [RecordingFile] {
        repository.fetchAll()
    }

    func delete(recording: RecordingFile) throws {
        try repository.delete(url: recording.url)
    }
}
