//
//  RecordingRepositoryImpl.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  RecordingRepository の具体実装（Documents ディレクトリに m4a を保存）

import AVFoundation
import Foundation

/// RecordingRepository の具体実装
final class RecordingRepositoryImpl: RecordingRepository {
    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 保存済み録音ファイルを新しい順に返す
    func fetchAll() -> [RecordingFile] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: documentsURL,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        return urls
            .filter { $0.pathExtension == "m4a" }
            .compactMap { url in
                let attrs = try? fileManager.attributesOfItem(atPath: url.path)
                let createdAt = attrs?[.creationDate] as? Date ?? Date()
                let fileSize = (attrs?[.size] as? Int) ?? 0

                // AVAudioFile で正確な duration を同期取得
                let duration: TimeInterval
                if let file = try? AVAudioFile(forReading: url) {
                    duration = Double(file.length) / file.fileFormat.sampleRate
                } else {
                    duration = 0
                }

                return RecordingFile(
                    id: UUID(),
                    url: url,
                    fileName: url.lastPathComponent,
                    createdAt: createdAt,
                    duration: duration,
                    fileSize: Int64(fileSize)
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// 指定URLの録音ファイルを削除する
    func delete(url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    /// 新しい録音の保存先URLを生成する（ファイル名: "yyyy-MM-dd_HH-mm-ss.m4a"）
    func newRecordingURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = formatter.string(from: Date()) + ".m4a"
        return documentsURL.appendingPathComponent(fileName)
    }
}
