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
    let japaneseName: String   // 日本語音階名・篠笛読み方（例: "シ", "ド"）
    let shinobueName: String?  // 篠笛の音階名（例: "一", "七の甲"）。範囲外はnil
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

    /// 半音ごとの日本語音階名（篠笛６本調子の読み方。A=シ, B♭=ド, C=レ … G=ラ）
    static let japaneseNoteNames = [
        "レ", "レ♯", "ミ", "ファ", "ファ♯", "ソ",
        "ソ♯", "ラ", "ラ♯", "シ", "ド", "ド♯"
    ]

    /// MIDIノート番号から篠笛の音階名へのマッピング（六本調子）
    /// 呂（低音域）: 一〜七、甲（高音域）: 七の甲〜五の甲
    static let shinobueNoteNames: [Int: String] = [
        69: "一",          // A4
        70: "二",          // B♭4
        71: "二（半）",    // B4
        72: "三",          // C5
        73: "三（半）",    // D♭5
        74: "四",          // D5
        75: "五",          // E♭5
        76: "六",          // E5
        77: "七",          // F5
        78: "七の甲",      // G♭5
        79: "筒音の甲",    // G5
        80: "ツの甲",      // A♭5
        81: "一の甲",      // A5
        82: "二の甲",      // B♭5
        83: "二の甲（半）", // B5
        84: "三の甲",      // C6
        85: "三の甲（半）", // D♭6
        86: "四の甲",      // D6
        87: "五の甲"       // E♭6
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
            shinobueName: shinobueNoteNames[midiNote],
            octave: octave
        )

        return (note: note, cents: cents)
    }

    /// 篠笛６本調子で使用する主要音符の周波数範囲
    static let shinobueFrequencyRange: ClosedRange<Float> = 124.0...720.0
}
