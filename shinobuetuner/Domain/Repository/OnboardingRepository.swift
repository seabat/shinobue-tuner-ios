//
//  OnboardingRepository.swift
//  shinobuetuner
//
//  初回起動時の案内（オンボーディング）の進行状況のリポジトリプロトコル

import Foundation

/// オンボーディングの進行状況を永続化するリポジトリのプロトコル
/// ※ TunerSettings とは別に保存する（「デフォルトに戻す」で進行状況が消えないようにするため）
protocol OnboardingRepository {
    /// 調子選択を完了済みかどうかを取得する
    func hasSelectedTuning() -> Bool

    /// 調子選択を完了済みとして記録する
    func markTuningSelected()
}
