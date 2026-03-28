//
//  TrimLeadingSilenceUseCase.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/03/28.
//
//  音声ファイルの先頭無音除去ユースケース

import Foundation

/// 先頭無音除去ユースケースのプロトコル
protocol TrimLeadingSilenceUseCaseProtocol {
    /// 指定したファイルの先頭の無音区間を除去する
    func callAsFunction(file: PlaybackFile) async throws
}

/// 先頭無音除去ユースケースの具体実装
final class TrimLeadingSilenceUseCase: TrimLeadingSilenceUseCaseProtocol {
    private let repository: any PlaybackFileRepository
    private let settingsRepository: any PlaybackSettingsRepository

    init(repository: any PlaybackFileRepository, settingsRepository: any PlaybackSettingsRepository) {
        self.repository = repository
        self.settingsRepository = settingsRepository
    }

    func callAsFunction(file: PlaybackFile) async throws {
        _ = try await repository.trimLeadingSilence(
            url: file.url,
            // 実行時に最新のしきい値をリポジトリから取得する
            threshold: settingsRepository.fetch().trimNoisePeakThreshold
        )
    }
}
