//
//  NoteInfo.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  音符の情報モデルと442Hz基準の12平均律変換ヘルパー

import Foundation

/// 音符の情報を表す構造体
struct NoteInfo {
    let midiNote: Int
    let frequency: Double      // 基準周波数（Hz）
    let westernName: String    // 西洋音階名（例: "A4", "B♭4"）
    let japaneseName: String   // 日本音階名・篠笛読み方（例: "シ", "ド"）
    let fingeringName: String?  // 運指名（例: "一", "七の甲"）。範囲外はnil
    let octave: Int
}

/// 周波数・音階名変換ヘルパー（442Hz基準の12平均律）
enum NoteHelper {
    /// 基準音: A4 = 442 Hz（篠笛 ６本調子）
    static let referenceFrequency: Double = 442.0
    /// A4のMIDIノート番号
    static let referenceMidiNote: Int = 69

    /// 半音ごとの西洋音階名（C=0 ... B=11）。篠笛６本調子はB♭楽器のためフラット表記を使用
    static let westernNoteNames = [
        "C", "D♭", "D", "E♭", "E", "F",
        "G♭", "G", "A♭", "A", "B♭", "B"
    ]

    /// 半音ごとの日本音階名（篠笛６本調子の読み方。A=シ, B♭=ド, C=レ … G=ラ）
    /// ローカライズ: 英語ロケールでは固定ド式ソルフェージュ（Do/Re/Mi...）表記になる
    static let japaneseNoteNames = [
        String(localized: "レ"), String(localized: "レ♯"), String(localized: "ミ"),
        String(localized: "ファ"), String(localized: "ファ♯"), String(localized: "ソ"),
        String(localized: "ソ♯"), String(localized: "ラ"), String(localized: "ラ♯"),
        String(localized: "シ"), String(localized: "ド"), String(localized: "ド♯")
    ]

    /// MIDIノート番号から運指名へのマッピング（六本調子）
    /// 呂音（低音域）: 筒音・一〜七  漢数字
    /// 甲音（高音域）: １〜７        アラビア数字（全角）
    /// 大甲（最高音域）: 1'〜4'      アラビア数字＋アポストロフィ
    /// ローカライズ: 英語ロケールでは呂音=接頭辞なし数字、甲音="K"接頭辞、大甲="K"接頭辞＋アポストロフィで表記
    static let fingeringNoteNames: [Int: String] = [
        69: String(localized: "筒音"),        // A4  シ（起点・基準音）
        70: String(localized: "一"),          // B♭4 ド
        71: String(localized: "一（半）"),    // B4  ド♯
        72: String(localized: "二"),          // C5  レ
        73: String(localized: "二（半）"),    // D♭5 レ♯
        74: String(localized: "三"),          // D5  ミ
        75: String(localized: "四"),          // E♭5 ファ
        76: String(localized: "四（半）"),    // E5  ファ♯
        77: String(localized: "五"),          // F5  ソ
        78: String(localized: "五（半）"),    // Gb5 ソ♯
        79: String(localized: "六"),          // G5  ラ
        80: String(localized: "六（半）"),    // A♭5 ラ♯
        81: String(localized: "七"),          // A5  シ
        82: String(localized: "１"),          // B♭5 ド
        83: String(localized: "１（半）"),    // B5  ド♯
        84: String(localized: "２"),          // C6  レ
        85: String(localized: "２（半）"),    // D♭6 レ♯
        86: String(localized: "３"),          // D6  ミ
        87: String(localized: "４"),          // E♭6 ファ
        88: String(localized: "４（半）"),    // E6  ファ♯
        89: String(localized: "５"),          // F6  ソ
        90: String(localized: "５（半）"),    // Gb6 ソ♯
        91: String(localized: "６"),          // G6  ラ
        92: String(localized: "６（半）"),    // Ab6 ラ♯
        93: String(localized: "７"),          // A6  シ
        94: String(localized: "1'"),          // Bb6 ド（大甲）
        95: String(localized: "1'（半）"),    // B6  ド♯（大甲）
        96: String(localized: "2'"),          // C7  レ（大甲）
        97: String(localized: "2'（半）"),    // Db7 レ♯（大甲）
        98: String(localized: "3'"),          // D7  ミ（大甲）
        99: String(localized: "4'")           // Eb7 ファ（大甲・１オクターブ上の４）
    ]

    /// MIDIノート番号から周波数を計算（442Hz基準）
    static func frequency(midiNote: Int) -> Double {
        return referenceFrequency * pow(2.0, Double(midiNote - referenceMidiNote) / 12.0)
    }

    /// 周波数から最近傍の音符情報とセント偏差を返す
    /// - Parameter freq: 計測した周波数（Hz）
    /// - Returns: 最近傍音符とセント偏差（正=シャープ, 負=フラット）
    static func closestNote(for freq: Float) -> (note: NoteInfo, cents: Float)? {
        guard freq > 50 else { return nil }

        // MIDIノート番号を浮動小数点で計算
        let midiFloat = Double(referenceMidiNote) + 12.0 * log2(Double(freq) / referenceFrequency)
        let midiNote = Int(midiFloat.rounded())

        // 有効範囲チェック
        guard midiNote >= 24 && midiNote <= 108 else { return nil }

        let refFreq = frequency(midiNote: midiNote)
        // セント偏差 = 1200 * log2(実測周波数 / 基準周波数)
        let cents = Float(1200.0 * log2(Double(freq) / refFreq))

        let noteIndex = ((midiNote % 12) + 12) % 12
        // MIDI規格: C4 = 60 → octave = 60/12 - 1 = 4
        let octave = (midiNote / 12) - 1

        let note = NoteInfo(
            midiNote: midiNote,
            frequency: refFreq,
            westernName: "\(westernNoteNames[noteIndex])\(octave)",
            japaneseName: japaneseNoteNames[noteIndex],
            fingeringName: fingeringNoteNames[midiNote],
            octave: octave
        )

        return (note: note, cents: cents)
    }

    /// 篠笛６本調子で使用する主要音符の周波数範囲
    static let shinobueFrequencyRange: ClosedRange<Float> = 124.0...720.0
}
