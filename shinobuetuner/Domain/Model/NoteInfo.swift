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
    let frequency: Double    // 基準周波数（Hz）
    let westernName: String  // 西洋音名（例: "A4", "C♯4"）
    let japaneseName: String // 日本語音名（例: "ラ", "ド♯"）
    let octave: Int
}

/// 周波数・音名変換ヘルパー（442Hz基準の12平均律）
enum NoteHelper {
    /// 基準音: A4 = 442 Hz（篠笛 ６本調子）
    static let referenceFrequency: Double = 442.0
    /// A4のMIDIノート番号
    static let referenceMidiNote: Int = 69

    /// 半音ごとの西洋音名（C=0, C♯=1, ... B=11）
    static let westernNoteNames = [
        "C", "C♯", "D", "D♯", "E", "F",
        "F♯", "G", "G♯", "A", "A♯", "B"
    ]

    /// 半音ごとの日本語音名
    static let japaneseNoteNames = [
        "ド", "ド♯", "レ", "レ♯", "ミ", "ファ",
        "ファ♯", "ソ", "ソ♯", "ラ", "ラ♯", "シ"
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
            octave: octave
        )

        return (note: note, cents: cents)
    }

    /// 篠笛６本調子で使用する主要音符の周波数範囲
    static let shinobueFrequencyRange: ClosedRange<Float> = 124.0...720.0
}
