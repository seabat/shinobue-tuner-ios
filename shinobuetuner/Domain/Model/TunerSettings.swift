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
    case rokuHon = 6   // 六本調子（対応済み）
    case nanahon = 7   // 七本調子
    case hachihon = 8  // 八本調子（対応済み）
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

    /// 六本調子からの半音差（一本増えるごとに半音高くなる。八本調子 = +2）
    /// 運指は調子によらず共通のため、六本調子のデータをこの差だけずらして各調子の値を求める
    var semitoneOffset: Int { rawValue - ShinobueTuning.rokuHon.rawValue }

    /// 主音（移動ドの「ド」・運指「一」の音）の音高クラス（C=0）。六本調子 = B♭(10)、八本調子 = C(0)
    var tonicPitchClass: Int { ((10 + semitoneOffset) % 12 + 12) % 12 }

    /// 半音ごとの音名表記（C=0 ... B=11）。♯/♭ の書き分けは調子ごとに決める
    /// ※ 未対応の調子は六本調子の表記を仮に使う（対応時にこの表を追加する）
    var westernNoteNames: [String] {
        switch self {
        case .hachihon:
            return ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]
        default:
            return ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
        }
    }

    /// 主音の音名（例: 六本調子 = "B♭"、八本調子 = "C"）
    var tonicName: String { westernNoteNames[tonicPitchClass] }

    /// 現在アプリが対応している調子かどうか
    var isSupported: Bool { self == .rokuHon || self == .hachihon }
}

/// 階名の表示方式
enum SolfegeSystem: Int, CaseIterable, Identifiable {
    /// 移動ド（調子の主音をドとする。六本調子 = B♭、八本調子 = C）
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

/// チューナーのゲージ中央に表示する内容
enum GaugeDisplayMode: Int, CaseIterable, Identifiable {
    /// 日本音階名（階名）＋ 西洋音階名
    case noteName  = 0
    /// 運指名
    case fingering = 1

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .noteName:  return String(localized: "音階名")
        case .fingering: return String(localized: "運指名")
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
    /// ゲージ中央に表示する内容（デフォルト: 音階名）
    var gaugeDisplayMode: GaugeDisplayMode = .noteName

    /// アンサンブル用高難度オプション（非推奨・実機テスト中）
    /// スペクトル幅の閾値（ビン数）：値が小さいほど判定が厳しい
    var ensembleSpectralWidthThreshold: Float = 5.0
    /// アンサンブル用高難度オプション（非推奨・実機テスト中）
    /// 安定性スコアの閾値（セント標準偏差）：値が小さいほど判定が厳しい
    var ensembleStabilityScoreThreshold: Float = 10.0
}
