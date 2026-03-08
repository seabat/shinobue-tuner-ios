//
//  TunerSettings.swift
//  shinobuetuner
//
//  チューニング成功判定の設定値（UserDefaultsに永続化）

import Foundation
import Combine

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

    var displayName: String { "\(rawValue)本調子" }

    /// 筒音（シ）の基準周波数（Hz）。六本調子 = 442Hz
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

/// チューナーの設定
final class TunerSettings: ObservableObject {
    /// チューニング成功とみなすセント閾値（デフォルト: 10セント）
    @Published var centThreshold: Double {
        didSet { UserDefaults.standard.set(centThreshold, forKey: "tuningCentThreshold") }
    }
    /// チューニング成功とみなす継続秒数（デフォルト: 1秒）
    @Published var durationSeconds: Double {
        didSet { UserDefaults.standard.set(durationSeconds, forKey: "tuningDurationSeconds") }
    }
    /// 選択中の調子（デフォルト: 六本調子）
    @Published var tuning: ShinobueTuning {
        didSet { UserDefaults.standard.set(tuning.rawValue, forKey: "selectedTuning") }
    }
    /// ピッチグラフを表示するかどうか（デフォルト: true）
    @Published var showPitchGraph: Bool {
        didSet { UserDefaults.standard.set(showPitchGraph, forKey: "showPitchGraph") }
    }

    nonisolated init() {
        let savedCent = UserDefaults.standard.double(forKey: "tuningCentThreshold")
        _centThreshold = Published(initialValue: savedCent > 0 ? savedCent : 10.0)

        let savedDuration = UserDefaults.standard.double(forKey: "tuningDurationSeconds")
        _durationSeconds = Published(initialValue: savedDuration > 0 ? savedDuration : 1.0)

        let savedTuning = UserDefaults.standard.integer(forKey: "selectedTuning")
        let tuning = ShinobueTuning(rawValue: savedTuning) ?? .rokuHon
        _tuning = Published(initialValue: tuning)

        let savedShowGraph = UserDefaults.standard.object(forKey: "showPitchGraph") as? Bool ?? true
        _showPitchGraph = Published(initialValue: savedShowGraph)
    }
}
