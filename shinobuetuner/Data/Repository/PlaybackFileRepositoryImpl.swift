//
//  PlaybackFileRepositoryImpl.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  PlaybackFileRepository の具体実装（Documents ディレクトリに m4a を保存）

import AVFoundation
import Foundation

/// PlaybackFileRepository の具体実装
final class PlaybackFileRepositoryImpl: PlaybackFileRepository {
    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 保存済み音声ファイルを新しい順に返す
    func fetchAll() -> [PlaybackFile] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: documentsURL,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        // m4a に加えて他アプリからインポートした音声フォーマットも表示する
        let supportedExtensions: Set<String> = ["m4a", "mp3", "wav", "aiff", "aif", "caf", "flac"]
        return urls
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
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

                return PlaybackFile(
                    url: url,
                    fileName: url.lastPathComponent,
                    createdAt: createdAt,
                    duration: duration,
                    fileSize: Int64(fileSize)
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// 指定URLの音声ファイルを削除する
    func delete(url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    /// 音声ファイルの名前を変更する（元の拡張子を維持）
    func rename(url: URL, newName: String) throws -> URL {
        let ext = url.pathExtension
        let newURL = url.deletingLastPathComponent()
            .appendingPathComponent(newName)
            .appendingPathExtension(ext)
        try fileManager.moveItem(at: url, to: newURL)
        return newURL
    }

    /// 外部から共有された音声ファイルを Documents ディレクトリにコピーして返す
    /// - 同名ファイルが存在する場合は "_2", "_3" ... を末尾に付けて重複回避
    func importFile(from url: URL) throws -> PlaybackFile {
        // セキュリティスコープ付きリソースへのアクセスを開始する
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
        let baseName = url.deletingPathExtension().lastPathComponent
        var destURL = documentsURL.appendingPathComponent(baseName).appendingPathExtension(ext)

        // 重複ファイル名の回避
        var counter = 2
        while fileManager.fileExists(atPath: destURL.path) {
            destURL = documentsURL
                .appendingPathComponent("\(baseName)_\(counter)")
                .appendingPathExtension(ext)
            counter += 1
        }

        try fileManager.copyItem(at: url, to: destURL)

        let attrs = try? fileManager.attributesOfItem(atPath: destURL.path)
        let createdAt = attrs?[.creationDate] as? Date ?? Date()
        let fileSize = (attrs?[.size] as? Int) ?? 0
        let duration: TimeInterval
        if let file = try? AVAudioFile(forReading: destURL) {
            duration = Double(file.length) / file.fileFormat.sampleRate
        } else {
            duration = 0
        }

        return PlaybackFile(
            url: destURL,
            fileName: destURL.lastPathComponent,
            createdAt: createdAt,
            duration: duration,
            fileSize: Int64(fileSize)
        )
    }

    /// 新しい音声ファイルの保存先URLを生成する（ファイル名: "yyyy-MM-dd_HH-mm-ss.m4a"）
    func newPlaybackFileURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = formatter.string(from: Date()) + ".m4a"
        return documentsURL.appendingPathComponent(fileName)
    }

    /// 先頭の無音区間を除去した新しいファイル "[頭出し]元のファイル名" を作成して返す
    /// - 先頭が既に有音の場合は元のURLをそのまま返す
    @discardableResult
    func trimLeadingSilence(url: URL, threshold: Float) async throws -> URL {
        guard let silenceEnd = try detectSilenceEnd(at: url, threshold: threshold),
              silenceEnd > 0 else { return url }

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let startTime = CMTime(seconds: silenceEnd, preferredTimescale: 44100)
        guard startTime < duration else { return url }

        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw TrimError.exportSessionCreationFailed
        }

        // 一時ファイルにエクスポートし、失敗時は defer でクリーンアップ
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        defer { try? fileManager.removeItem(at: tempURL) }

        session.timeRange = CMTimeRange(start: startTime, end: duration)
        try await session.export(to: tempURL, as: .m4a)

        // 保存先: "[頭出し]元のファイル名.m4a"（非破壊・出力フォーマットに合わせて拡張子を m4a に統一）
        let baseName = url.deletingPathExtension().lastPathComponent
        let destURL = url.deletingLastPathComponent()
            .appendingPathComponent("[頭出し]" + baseName)
            .appendingPathExtension("m4a")
        if fileManager.fileExists(atPath: destURL.path) {
            try fileManager.removeItem(at: destURL)
        }
        try fileManager.moveItem(at: tempURL, to: destURL)
        return destURL
    }

    // MARK: - Private

    /// 先頭の無音が終わる正確なフレーム位置（秒）を返す。先頭から有音なら nil を返す
    private func detectSilenceEnd(at url: URL, threshold: Float) throws -> TimeInterval? {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let chunkFrames: AVAudioFrameCount = 4096
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkFrames) else {
            return nil
        }

        var framePosition: AVAudioFramePosition = 0

        while audioFile.framePosition < audioFile.length {
            let remaining = AVAudioFrameCount(audioFile.length - audioFile.framePosition)
            let framesToRead = min(chunkFrames, remaining)
            try audioFile.read(into: buffer, frameCount: framesToRead)

            // チャンク内で最初に有音となるフレームを1サンプル精度で探す
            if let offsetInChunk = findFirstLoudFrame(buffer: buffer, frameCount: framesToRead, threshold: threshold) {
                let loudFramePosition = framePosition + AVAudioFramePosition(offsetInChunk)
                if loudFramePosition == 0 { return nil }
                return Double(loudFramePosition) / format.sampleRate
            }
            framePosition += AVAudioFramePosition(framesToRead)
        }
        return nil // 全体が無音
    }

    /// チャンク内で最初に閾値を超えるフレームのインデックスを返す
    private func findFirstLoudFrame(buffer: AVAudioPCMBuffer, frameCount: AVAudioFrameCount, threshold: Float) -> Int? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let samples = channelData[0]
        for i in 0..<Int(frameCount) {
            if abs(samples[i]) >= threshold {
                return i
            }
        }
        return nil
    }
}

// MARK: - Errors

enum TrimError: LocalizedError {
    case exportSessionCreationFailed

    var errorDescription: String? {
        switch self {
        case .exportSessionCreationFailed:
            return "エクスポートセッションの作成に失敗しました"
        }
    }
}
