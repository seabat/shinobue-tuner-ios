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
    static let japaneseNoteNames = [
        "レ", "レ♯", "ミ", "ファ", "ファ♯", "ソ",
        "ソ♯", "ラ", "ラ♯", "シ", "ド", "ド♯"
    ]

    /// MIDIノート番号から運指名へのマッピング（六本調子）
    /// 呂音（低音域）: 筒音・一〜七  漢数字
    /// 甲音（高音域）: １〜５        アラビア数字
    static let fingeringNoteNames: [Int: String] = [
        69: "筒音",        // A4  シ（起点・基準音）
        70: "一",          // B♭4 ド
        71: "一（半）",    // B4  ド♯
        72: "二",          // C5  レ
        73: "二（半）",    // D♭5 レ♯
        74: "三",          // D5  ミ
        75: "四",          // E♭5 ファ
        76: "四（半）",    // E5  ファ♯
        77: "五",          // F5  ソ
        78: "五（半）",    // Gb5 ソ♯
        79: "六",          // G5  ラ
        80: "六（半）",    // A♭5 ラ♯
        81: "七",          // A5  シ
        82: "１",          // B♭5 ド
        83: "１（半）",    // B5  ド♯
        84: "２",          // C6  レ
        85: "２（半）",    // D♭6 レ♯
        86: "３",          // D6  ミ
        87: "４",          // E♭6 ファ
        88: "４（半）",    // E6  ファ♯
        89: "５"           // F6  ソ
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
