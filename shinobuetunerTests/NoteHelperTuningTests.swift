//
//  NoteHelperTuningTests.swift
//  shinobuetunerTests
//
//  六本調子・八本調子の運指名／音名／階名／周波数が比較表（PDF「篠笛_六本調子_八本調子_比較表」）と一致するかを検証する
//  ※ 運指名・階名はローカライズ文字列のため、日本語ロケールで実行すること（xcodebuild test -testLanguage ja）

import Testing
@testable import shinobuetuner

/// 比較表の1行（同じ運指の六本調子・八本調子の値）
struct TuningTableRow: CustomStringConvertible {
    let fingering: String
    let movableDo: String
    let rokuHonWestern: String
    let rokuHonFixedDo: String
    let rokuHonHz: Double
    let hachiHonWestern: String
    let hachiHonFixedDo: String
    let hachiHonHz: Double

    var description: String { fingering }
}

/// 比較表（高い音から順）
private let comparisonTable: [TuningTableRow] = [
    .init(fingering: "５",         movableDo: "ソ",    rokuHonWestern: "F6",  rokuHonFixedDo: "ファ",  rokuHonHz: 1403.263, hachiHonWestern: "G6",  hachiHonFixedDo: "ソ",    hachiHonHz: 1575.109),
    .init(fingering: "４（半）",   movableDo: "ファ♯", rokuHonWestern: "E6",  rokuHonFixedDo: "ミ",    rokuHonHz: 1324.503, hachiHonWestern: "F♯6", hachiHonFixedDo: "ファ♯", hachiHonHz: 1486.705),
    .init(fingering: "４",         movableDo: "ファ",  rokuHonWestern: "E♭6", rokuHonFixedDo: "ミ♭",   rokuHonHz: 1250.165, hachiHonWestern: "F6",  hachiHonFixedDo: "ファ",  hachiHonHz: 1403.263),
    .init(fingering: "３",         movableDo: "ミ",    rokuHonWestern: "D6",  rokuHonFixedDo: "レ",    rokuHonHz: 1179.998, hachiHonWestern: "E6",  hachiHonFixedDo: "ミ",    hachiHonHz: 1324.503),
    .init(fingering: "２（半）",   movableDo: "レ♯",   rokuHonWestern: "D♭6", rokuHonFixedDo: "レ♭",   rokuHonHz: 1113.770, hachiHonWestern: "E♭6", hachiHonFixedDo: "ミ♭",   hachiHonHz: 1250.165),
    .init(fingering: "２",         movableDo: "レ",    rokuHonWestern: "C6",  rokuHonFixedDo: "ド",    rokuHonHz: 1051.259, hachiHonWestern: "D6",  hachiHonFixedDo: "レ",    hachiHonHz: 1179.998),
    .init(fingering: "１（半）",   movableDo: "ド♯",   rokuHonWestern: "B5",  rokuHonFixedDo: "シ",    rokuHonHz:  992.256, hachiHonWestern: "C♯6", hachiHonFixedDo: "ド♯",   hachiHonHz: 1113.770),
    .init(fingering: "１",         movableDo: "ド",    rokuHonWestern: "B♭5", rokuHonFixedDo: "シ♭",   rokuHonHz:  936.565, hachiHonWestern: "C6",  hachiHonFixedDo: "ド",    hachiHonHz: 1051.259),
    .init(fingering: "七",         movableDo: "シ",    rokuHonWestern: "A5",  rokuHonFixedDo: "ラ",    rokuHonHz:  884.000, hachiHonWestern: "B5",  hachiHonFixedDo: "シ",    hachiHonHz:  992.256),
    .init(fingering: "六（半）",   movableDo: "ラ♯",   rokuHonWestern: "A♭5", rokuHonFixedDo: "ラ♭",   rokuHonHz:  834.385, hachiHonWestern: "B♭5", hachiHonFixedDo: "シ♭",   hachiHonHz:  936.565),
    .init(fingering: "六",         movableDo: "ラ",    rokuHonWestern: "G5",  rokuHonFixedDo: "ソ",    rokuHonHz:  787.554, hachiHonWestern: "A5",  hachiHonFixedDo: "ラ",    hachiHonHz:  884.000),
    .init(fingering: "五（半）",   movableDo: "ソ♯",   rokuHonWestern: "G♭5", rokuHonFixedDo: "ソ♭",   rokuHonHz:  743.352, hachiHonWestern: "A♭5", hachiHonFixedDo: "ラ♭",   hachiHonHz:  834.385),
    .init(fingering: "五",         movableDo: "ソ",    rokuHonWestern: "F5",  rokuHonFixedDo: "ファ",  rokuHonHz:  701.631, hachiHonWestern: "G5",  hachiHonFixedDo: "ソ",    hachiHonHz:  787.554),
    .init(fingering: "四（半）",   movableDo: "ファ♯", rokuHonWestern: "E5",  rokuHonFixedDo: "ミ",    rokuHonHz:  662.252, hachiHonWestern: "F♯5", hachiHonFixedDo: "ファ♯", hachiHonHz:  743.352),
    .init(fingering: "四",         movableDo: "ファ",  rokuHonWestern: "E♭5", rokuHonFixedDo: "ミ♭",   rokuHonHz:  625.082, hachiHonWestern: "F5",  hachiHonFixedDo: "ファ",  hachiHonHz:  701.631),
    .init(fingering: "三",         movableDo: "ミ",    rokuHonWestern: "D5",  rokuHonFixedDo: "レ",    rokuHonHz:  589.999, hachiHonWestern: "E5",  hachiHonFixedDo: "ミ",    hachiHonHz:  662.252),
    .init(fingering: "二（半）",   movableDo: "レ♯",   rokuHonWestern: "D♭5", rokuHonFixedDo: "レ♭",   rokuHonHz:  556.885, hachiHonWestern: "E♭5", hachiHonFixedDo: "ミ♭",   hachiHonHz:  625.082),
    .init(fingering: "二",         movableDo: "レ",    rokuHonWestern: "C5",  rokuHonFixedDo: "ド",    rokuHonHz:  525.630, hachiHonWestern: "D5",  hachiHonFixedDo: "レ",    hachiHonHz:  589.999),
    .init(fingering: "一（半）",   movableDo: "ド♯",   rokuHonWestern: "B4",  rokuHonFixedDo: "シ",    rokuHonHz:  496.128, hachiHonWestern: "C♯5", hachiHonFixedDo: "ド♯",   hachiHonHz:  556.885),
    .init(fingering: "一",         movableDo: "ド",    rokuHonWestern: "B♭4", rokuHonFixedDo: "シ♭",   rokuHonHz:  468.283, hachiHonWestern: "C5",  hachiHonFixedDo: "ド",    hachiHonHz:  525.630),
    .init(fingering: "一（メリ）", movableDo: "シ",    rokuHonWestern: "A4",  rokuHonFixedDo: "ラ",    rokuHonHz:  442.000, hachiHonWestern: "B4",  hachiHonFixedDo: "シ",    hachiHonHz:  496.128),
    .init(fingering: "筒音（半）", movableDo: "ラ♯",   rokuHonWestern: "A♭4", rokuHonFixedDo: "ラ♭",   rokuHonHz:  417.192, hachiHonWestern: "B♭4", hachiHonFixedDo: "シ♭",   hachiHonHz:  468.283),
    .init(fingering: "筒音",       movableDo: "ラ",    rokuHonWestern: "G4",  rokuHonFixedDo: "ソ",    rokuHonHz:  393.777, hachiHonWestern: "A4",  hachiHonFixedDo: "ラ",    hachiHonHz:  442.000),
]

@MainActor
struct NoteHelperTuningTests {

    @Test("六本調子の名称・周波数が比較表と一致する", arguments: comparisonTable)
    func rokuHon(row: TuningTableRow) throws {
        try verify(
            tuning: .rokuHon, row: row,
            western: row.rokuHonWestern, fixedDo: row.rokuHonFixedDo, hz: row.rokuHonHz
        )
    }

    @Test("八本調子の名称・周波数が比較表と一致する", arguments: comparisonTable)
    func hachiHon(row: TuningTableRow) throws {
        try verify(
            tuning: .hachihon, row: row,
            western: row.hachiHonWestern, fixedDo: row.hachiHonFixedDo, hz: row.hachiHonHz
        )
    }

    @Test("八本調子は六本調子の全音（半音2つ）上")
    func semitoneOffset() {
        #expect(ShinobueTuning.rokuHon.semitoneOffset == 0)
        #expect(ShinobueTuning.hachihon.semitoneOffset == 2)
        #expect(ShinobueTuning.rokuHon.tonicName == "B♭")
        #expect(ShinobueTuning.hachihon.tonicName == "C")
    }

    @Test("対応済みの調子は六本・八本のみ")
    func supportedTunings() {
        #expect(ShinobueTuning.allCases.filter(\.isSupported) == [.rokuHon, .hachihon])
    }

    /// 比較表の Hz から音を逆引きし、運指名・音名・階名（移動ド／固定ド）・周波数を検証する
    private func verify(tuning: ShinobueTuning, row: TuningTableRow, western: String, fixedDo: String, hz: Double) throws {
        let result = try #require(NoteHelper.closestNote(for: Float(hz), tuning: tuning))
        let note = result.note

        #expect(note.fingeringName == row.fingering)
        #expect(note.westernName == western)
        #expect(note.japaneseName == row.movableDo)
        #expect(NoteHelper.solfegeName(midiNote: note.midiNote, system: .movable, tuning: tuning) == row.movableDo)
        #expect(NoteHelper.solfegeName(midiNote: note.midiNote, system: .fixed, tuning: tuning) == fixedDo)
        // 比較表は小数第3位で丸めているため、丸め誤差（0.0005）以内で一致すればよい
        #expect(abs(NoteHelper.frequency(midiNote: note.midiNote) - hz) <= 0.0005 + 1e-9)
    }
}
