//
//  PitchRepositoryImpl.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  PitchRepository プロトコルの具体実装（PitchDataSource に委譲）

import Combine
import Foundation

/// PitchRepository の具体実装
final class PitchRepositoryImpl: PitchRepository {
    private let dataSource: any PitchDataSource

    /// - Parameter dataSource: 入力元。省略時はマイク（Debug ビルドで起動引数 `-UITestAudioFile` があれば音声ファイル）
    init(dataSource: (any PitchDataSource)? = nil) {
        self.dataSource = dataSource ?? Self.makeDefaultDataSource()
    }

    /// 既定の入力元を生成する
    private static func makeDefaultDataSource() -> any PitchDataSource {
        #if DEBUG
        if let fileDataSource = AudioFileDataSource.fromLaunchArguments() {
            return fileDataSource
        }
        #endif
        return MicrophoneDataSource()
    }

    var pitchPublisher: AnyPublisher<Float, Never> {
        dataSource.publisher
    }

    var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> {
        dataSource.spectrumPublisher
    }

    func startMonitoring() {
        dataSource.startCapture()
    }

    func stopMonitoring() {
        dataSource.stopCapture()
    }

    func requestPermission() async -> Bool {
        await dataSource.requestPermission()
    }

    func startRecording(to url: URL) throws {
        try dataSource.startRecording(to: url)
    }

    func stopRecording() {
        dataSource.stopRecording()
    }
}
