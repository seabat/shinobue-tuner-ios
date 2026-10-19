//
//  ScaleAudioPitchDetectionTests.swift
//  shinobuetunerTests
//
//  テスト用音源（ド〜ドを1音1秒ずつ鳴らした .m4a）をピッチ検出に通し、音の順序・名称・精度を検証する
//  音源は docs/test/scripts/generate_scale_m4a.sh で生成する（Maestro の TunerMainScreen テストでも同じ音源を使う）
//  ※ 運指名・階名はローカライズ文字列のため、日本語ロケールで実行すること（xcodebuild test -testLanguage ja）

import AVFoundation
import Foundation
import Testing
@testable import shinobuetuner

/// テストバンドルを特定するためのクラス
private final class BundleToken {}

/// 音源の1音分の期待値
struct ExpectedScaleNote {
    let fingering: String
    let solfege: String
    let western: String
}

/// 調子ごとのテスト用音源と期待値
struct ScaleAudioCase: CustomStringConvertible {
    let fileName: String
    let tuning: ShinobueTuning
    let notes: [ExpectedScaleNote]

    var description: String { fileName }
}

private let scaleAudioCases: [ScaleAudioCase] = [
    .init(fileName: "rokuhon_scale", tuning: .rokuHon, notes: [
        .init(fingering: "１",  solfege: "ド",   western: "B♭5"),
        .init(fingering: "２",  solfege: "レ",   western: "C6"),
        .init(fingering: "３",  solfege: "ミ",   western: "D6"),
        .init(fingering: "４",  solfege: "ファ", western: "E♭6"),
        .init(fingering: "５",  solfege: "ソ",   western: "F6"),
        .init(fingering: "６",  solfege: "ラ",   western: "G6"),
        .init(fingering: "７",  solfege: "シ",   western: "A6"),
        .init(fingering: "1'",  solfege: "ド",   western: "B♭6"),
    ]),
    .init(fileName: "hachihon_scale", tuning: .hachihon, notes: [
        .init(fingering: "１",  solfege: "ド",   western: "C6"),
        .init(fingering: "２",  solfege: "レ",   western: "D6"),
        .init(fingering: "３",  solfege: "ミ",   western: "E6"),
        .init(fingering: "４",  solfege: "ファ", western: "F6"),
        .init(fingering: "５",  solfege: "ソ",   western: "G6"),
        .init(fingering: "６",  solfege: "ラ",   western: "A6"),
        .init(fingering: "７",  solfege: "シ",   western: "B6"),
        .init(fingering: "1'",  solfege: "ド",   western: "C7"),
    ]),
]

struct ScaleAudioPitchDetectionTests {
    /// 1音の長さ（秒）
    private let noteDuration = 1.0
    /// 音の切り替わり付近（フェード・FFT窓のまたぎ）を判定から除く幅（秒）
    private let boundaryMargin = 0.15
    /// 許容するセント偏差
    private let centTolerance: Float = 5

    @Test(arguments: scaleAudioCases)
    func 音源の各音が順番どおりに正しく検出される(testCase: ScaleAudioCase) throws {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: testCase.fileName, withExtension: "m4a"))
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let sampleRate = Float(format.sampleRate)
        let fftSize = 4096

        // 本番のタップと同じく fftSize フレームずつ切り出して検出する
        var detections: [(time: Double, pitch: Float)] = []
        while file.framePosition < file.length {
            let startTime = Double(file.framePosition) / format.sampleRate
            let chunk = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(fftSize)))
            try file.read(into: chunk, frameCount: AVAudioFrameCount(fftSize))
            guard chunk.frameLength == AVAudioFrameCount(fftSize) else { break }
            let pitch = MicrophoneDataSource.detectPitch(buffer: chunk, sampleRate: sampleRate, fftSize: fftSize)
            detections.append((startTime, pitch))
        }

        let chunkDuration = Double(fftSize) / format.sampleRate
        for (index, expected) in testCase.notes.enumerated() {
            let noteStart = Double(index) * noteDuration
            // 切り替わり付近を除き、音の内側に完全に収まる区間だけを判定する
            let inside = detections.filter {
                $0.time >= noteStart + boundaryMargin && $0.time + chunkDuration <= noteStart + noteDuration - boundaryMargin
            }
            #expect(!inside.isEmpty, "\(index + 1)音目の判定区間がありません")

            for detection in inside {
                let result = try #require(
                    NoteHelper.closestNote(for: detection.pitch, tuning: testCase.tuning),
                    "\(index + 1)音目（\(String(format: "%.2f", detection.time))秒）で音が検出されません"
                )
                let midiNote = result.note.midiNote
                let label = "\(index + 1)音目（\(String(format: "%.2f", detection.time))秒・\(detection.pitch)Hz）"
                #expect(result.note.westernName == expected.western, "\(label)")
                #expect(result.note.fingeringName == expected.fingering, "\(label)")
                #expect(NoteHelper.solfegeName(midiNote: midiNote, system: .movable, tuning: testCase.tuning) == expected.solfege, "\(label)")
                #expect(abs(result.cents) <= centTolerance, "\(label) \(result.cents) セント")
            }
        }
    }
}
