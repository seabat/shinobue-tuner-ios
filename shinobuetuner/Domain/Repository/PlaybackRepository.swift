//
//  PlaybackRepository.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  音声再生リポジトリのプロトコル定義

import Combine
import Foundation

/// 音声ファイルの再生を担うリポジトリのプロトコル
protocol PlaybackRepository {
    /// 現在の再生位置（秒）をemitするパブリッシャー
    var playbackTimePublisher: AnyPublisher<TimeInterval, Never> { get }

    /// 再生中かどうかをemitするパブリッシャー
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }

    /// 指定URLの音声ファイルを再生する
    func play(url: URL) throws

    /// 再生を一時停止する
    func pause()

    /// 一時停止した再生を再開する
    func resume()

    /// 再生を停止してリソースを解放する
    func stop()

    /// 指定した位置（秒）にシークする
    func seek(to time: TimeInterval)
}
