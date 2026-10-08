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
    let westernName: String    // 西洋音階名（例: "A4", "B♭4"）。♯/♭ は調子に従う
    let japaneseName: String   // 日本音階名（移動ド。例: "シ", "ド"）
    let fingeringName: String?  // 運指名（例: "一", "七の甲"）。範囲外はnil
    let octave: Int
}

/// 周波数・音階名変換ヘルパー（442Hz基準の12平均律）
/// 周波数・MIDIノート番号は調子に依存しない絶対値。名称（運指名・音名・階名）だけが調子に依存する
enum NoteHelper {
    /// 基準音: A4 = 442 Hz
    static let referenceFrequency: Double = 442.0
    /// A4のMIDIノート番号
    static let referenceMidiNote: Int = 69

    /// 半音ごとの日本音階名（移動ド。主音からの半音数 0=ド … 11=シ）
    /// ローカライズ: 英語ロケールでも移動ド式ソルフェージュ（Do/Re/Mi...）表記になる
    static let movableDoNoteNames = [
        String(localized: "ド"), String(localized: "ド♯"), String(localized: "レ"),
        String(localized: "レ♯"), String(localized: "ミ"), String(localized: "ファ"),
        String(localized: "ファ♯"), String(localized: "ソ"), String(localized: "ソ♯"),
        String(localized: "ラ"), String(localized: "ラ♯"), String(localized: "シ")
    ]

    /// 固定ドの幹音名（音名の英字 → 階名）。変化記号（♯/♭）は音名からそのまま引き継ぐ
    static let fixedDoSyllables: [Character: String] = [
        "C": String(localized: "ド"), "D": String(localized: "レ"), "E": String(localized: "ミ"),
        "F": String(localized: "ファ"), "G": String(localized: "ソ"), "A": String(localized: "ラ"),
        "B": String(localized: "シ")
    ]

    /// 六本調子のMIDIノート番号から運指名へのマッピング
    /// 他の調子では `midiNote - tuning.semitoneOffset` で六本調子の番号に換算して引く
    /// 呂音（低音域）: 筒音・一（メリ）・一〜七  漢数字
    /// 甲音（高音域）: １〜７        アラビア数字（全角）
    /// 大甲（最高音域）: 1'〜4'      アラビア数字＋アポストロフィ
    /// ローカライズ: 英語ロケールでは呂音=接頭辞なし数字、甲音="K"接頭辞、大甲="K"接頭辞＋アポストロフィで表記
    static let fingeringNoteNames: [Int: String] = [
        67: String(localized: "筒音"),        // G4  ラ（最低音）
        68: String(localized: "筒音（半）"),  // A♭4 ラ♯
        69: String(localized: "一（メリ）"),  // A4  シ
        70: String(localized: "一"),          // B♭4 ド（主音）
        71: String(localized: "一（半）"),    // B4  ド♯
        72: String(localized: "二"),          // C5  レ
        73: String(localized: "二（半）"),    // D♭5 レ♯
        74: String(localized: "三"),          // D5  ミ
        75: String(localized: "四"),          // E♭5 ファ
        76: String(localized: "四（半）"),    // E5  ファ♯
        77: String(localized: "五"),          // F5  ソ
        78: String(localized: "五（半）"),    // G♭5 ソ♯
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
        90: String(localized: "５（半）"),    // G♭6 ソ♯
        91: String(localized: "６"),          // G6  ラ
        92: String(localized: "６（半）"),    // A♭6 ラ♯
        93: String(localized: "７"),          // A6  シ
        94: String(localized: "1'"),          // B♭6 ド（大甲）
        95: String(localized: "1'（半）"),    // B6  ド♯（大甲）
        96: String(localized: "2'"),          // C7  レ（大甲）
        97: String(localized: "2'（半）"),    // D♭7 レ♯（大甲）
        98: String(localized: "3'"),          // D7  ミ（大甲）
        99: String(localized: "4'")           // E♭7 ファ（大甲・１オクターブ上の４）
    ]

    /// 六本調子の運指がある MIDI ノート番号の範囲（筒音 G4 〜 4' E♭7）
    static let rokuHonFingeringRange: ClosedRange<Int> = 67...99

    /// MIDIノート番号から周波数を計算（442Hz基準）
    static func frequency(midiNote: Int) -> Double {
        return referenceFrequency * pow(2.0, Double(midiNote - referenceMidiNote) / 12.0)
    }

    /// MIDIノート番号から音名（例: "E♭5", "F♯6"）を返す。♯/♭ の書き分けは調子に従う
    static func westernName(midiNote: Int, tuning: ShinobueTuning) -> String {
        // MIDI規格: C4 = 60 → octave = 60/12 - 1 = 4
        let octave = (midiNote / 12) - 1
        return "\(tuning.westernNoteNames[pitchClass(midiNote)])\(octave)"
    }

    /// MIDIノート番号から運指名を返す。運指の範囲外は nil
    static func fingeringName(midiNote: Int, tuning: ShinobueTuning) -> String? {
        fingeringNoteNames[midiNote - tuning.semitoneOffset]
    }

    /// MIDIノート番号・表示方式・調子から階名を返す
    /// - 移動ド: 調子の主音をドとする（同じ運指なら調子が違っても同じ階名）
    /// - 固定ド: C をドとし、♯/♭ は調子の音名表記に従う（例: E♭ → ミ♭）
    static func solfegeName(midiNote: Int, system: SolfegeSystem, tuning: ShinobueTuning) -> String {
        switch system {
        case .movable:
            return movableDoNoteNames[pitchClass(midiNote - tuning.tonicPitchClass)]
        case .fixed:
            let name = tuning.westernNoteNames[pitchClass(midiNote)]
            guard let letter = name.first, let syllable = fixedDoSyllables[letter] else { return name }
            return syllable + name.dropFirst()
        }
    }

    /// 周波数から最近傍の音符情報とセント偏差を返す
    /// - Parameters:
    ///   - freq: 計測した周波数（Hz）
    ///   - tuning: 名称（運指名・音名・階名）に使う調子。セント偏差は調子に依存しない
    /// - Returns: 最近傍音符とセント偏差（正=シャープ, 負=フラット）
    static func closestNote(for freq: Float, tuning: ShinobueTuning = .rokuHon) -> (note: NoteInfo, cents: Float)? {
        guard freq > 50 else { return nil }

        // MIDIノート番号を浮動小数点で計算
        let midiFloat = Double(referenceMidiNote) + 12.0 * log2(Double(freq) / referenceFrequency)
        let midiNote = Int(midiFloat.rounded())

        // 有効範囲チェック
        guard midiNote >= 24 && midiNote <= 108 else { return nil }

        let refFreq = frequency(midiNote: midiNote)
        // セント偏差 = 1200 * log2(実測周波数 / 基準周波数)
        let cents = Float(1200.0 * log2(Double(freq) / refFreq))

        let note = NoteInfo(
            midiNote: midiNote,
            frequency: refFreq,
            westernName: westernName(midiNote: midiNote, tuning: tuning),
            japaneseName: solfegeName(midiNote: midiNote, system: .movable, tuning: tuning),
            fingeringName: fingeringName(midiNote: midiNote, tuning: tuning),
            octave: (midiNote / 12) - 1
        )

        return (note: note, cents: cents)
    }

    /// MIDIノート番号（または半音差）を 0〜11 の音高クラスに正規化する（C=0）
    private static func pitchClass(_ value: Int) -> Int {
        ((value % 12) + 12) % 12
    }
}
