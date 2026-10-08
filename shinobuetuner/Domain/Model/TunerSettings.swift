//
//  TunerSettings.swift
//  shinobuetuner
//
//  チューニング成功判定の設定値

import Foundation

/// 篠笛の調子
enum ShinobueTuning: Int, CaseIterable, Identifiable {
    case honCho  = 1   // 一本調子
    case niHon   = 2   // 二本調子
    case sanHon  = 3   // 三本調子
    case yonHon  = 4   // 四本調子
    case goHon   = 5   // 五本調子
    case rokuHon = 6   // 六本調子（現在対応済み）
    case nanahon = 7   // 七本調子
    case hachihon = 8  // 八本調子
    case kyuhon  = 9   // 九本調子
    case juppon  = 10  // 十本調子
    case juippon = 11  // 十一本調子
    case junihon = 12  // 十二本調子
    case jusanbon = 13 // 十三本調子

    var id: Int { rawValue }

    var displayName: String {
        let format = String(localized: "tuning.displayName.format", defaultValue: "%d本調子")
        return String(format: format, rawValue)
    }

    /// 基準音 A4（一（メリ）・シ）の周波数（Hz）。六本調子 = 442Hz
    /// ※ 他の調子は未対応（将来実装予定）
    var referenceFrequency: Double {
        switch self {
        case .rokuHon: return 442.0
        default:       return 442.0  // 未対応のため六本調子と同じ値を返す
        }
    }

    /// 現在アプリが対応している調子かどうか
    var isSupported: Bool { self == .rokuHon }
}

/// 階名の表示方式
enum SolfegeSystem: Int, CaseIterable, Identifiable {
    /// 移動ド（六本調子の主音 B♭ をドとする）
    case movable = 0
    /// 固定ド（C をドとする）
    case fixed   = 1

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .movable: return String(localized: "移動ド")
        case .fixed:   return String(localized: "固定ド")
        }
    }
}

/// チューナーの設定値
struct TunerSettings {
    /// チューニング成功とみなすセント閾値（デフォルト: 10セント）
    var centThreshold: Double = 10.0
    /// チューニング成功とみなす継続秒数（デフォルト: 1秒）
    var durationSeconds: Double = 1.0
    /// 選択中の調子（デフォルト: 六本調子）
    var tuning: ShinobueTuning = .rokuHon
    /// ピッチグラフを表示するかどうか（デフォルト: true）
    var showPitchGraph: Bool = true
    /// 階名の表示方式（デフォルト: 移動ド）
    var solfegeSystem: SolfegeSystem = .movable

    /// アンサンブル用高難度オプション（非推奨・実機テスト中）
    /// スペクトル幅の閾値（ビン数）：値が小さいほど判定が厳しい
    var ensembleSpectralWidthThreshold: Float = 5.0
    /// アンサンブル用高難度オプション（非推奨・実機テスト中）
    /// 安定性スコアの閾値（セント標準偏差）：値が小さいほど判定が厳しい
    var ensembleStabilityScoreThreshold: Float = 10.0
}
