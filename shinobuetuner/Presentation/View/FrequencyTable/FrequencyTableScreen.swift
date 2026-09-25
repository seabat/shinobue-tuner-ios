//
//  FrequencyTableScreen.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/03/01.
//
//  篠笛六本調子 音階周波数表

import SwiftUI

/// 篠笛六本調子の音階周波数表を表示するビュー
struct FrequencyTableScreen: View {

    // 六本調子（シ=442Hz基準）音階周波数表（高い音から順）
    private let rows: [FrequencyRow] = [
        FrequencyRow("4'",       "ファ",  2500.328, "Eb7"),
        FrequencyRow("3'",       "ミ",    2360.029, "D7"),
        FrequencyRow("2'（半）", "レ♯",  2227.540, "Db7"),
        FrequencyRow("2'",       "レ",    2102.519, "C7"),
        FrequencyRow("1'（半）", "ド♯",  1984.512, "B6"),
        FrequencyRow("1'",       "ド",    1873.131, "Bb6", isHighlighted: true),
        FrequencyRow("７",       "シ",    1768.000, "A6"),
        FrequencyRow("６（半）", "ラ♯",  1668.770, "Ab6"),
        FrequencyRow("６",       "ラ",    1575.116, "G6"),
        FrequencyRow("５（半）", "ソ♯",  1486.784, "Gb6"),
        FrequencyRow("５",       "ソ",    1403.262, "F6"),
        FrequencyRow("４（半）", "ファ♯", 1324.504, "E6"),
        FrequencyRow("４",       "ファ",  1250.164, "Eb6"),
        FrequencyRow("３",       "ミ",    1179.998, "D6"),
        FrequencyRow("２（半）", "レ♯",   1113.770, "Db6"),
        FrequencyRow("２",       "レ",    1051.260, "C6"),
        FrequencyRow("１（半）", "ド♯",    992.256, "B5"),
        FrequencyRow("１",       "ド",     936.566, "Bb5"),
        FrequencyRow("七",       "シ",     884.000, "A5"),
        FrequencyRow("六（半）", "ラ♯",    834.385, "Ab5"),
        FrequencyRow("六",       "ラ",     787.558, "G5"),
        FrequencyRow("五（半）", "ソ♯",   743.352, "Gb5"),
        FrequencyRow("五",       "ソ",     701.631, "F5"),
        FrequencyRow("四（半）", "ファ♯",  662.252, "E5"),
        FrequencyRow("四",       "ファ",   625.082, "Eb5"),
        FrequencyRow("三",       "ミ",     589.999, "D5"),
        FrequencyRow("二（半）", "レ♯",    556.885, "Db5"),
        FrequencyRow("二",       "レ",     525.630, "C5"),
        FrequencyRow("一（半）", "ド♯",    496.128, "B4"),
        FrequencyRow("一",       "ド",     468.283, "Bb4"),
        FrequencyRow("筒音",     "シ",     442.000, "A4", isHighlighted: true),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    // ─── ヘッダー行 ───
                    HStack(spacing: 0) {
                        Text("運指").headerStyle()
                        Text("日本").headerStyle()
                        Text("西洋").headerStyle()
                        Text("Hz").headerStyle(alignment: .trailing)
                    }
                    .frame(height: 32)
                    .padding(.horizontal, 16)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.18))

                    // ─── データ行 ───
                    ForEach(rows) { row in
                        HStack(spacing: 0) {
                            // 運指名
                            Text(row.fingeringName)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(row.isHighlighted ? Color.cyan : .white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // 日本音階名
                            Text(row.japaneseName)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(row.isHighlighted ? Color.cyan : .white.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // 西洋音階名
                            Text(row.westernName)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(row.isHighlighted ? Color.cyan : .white.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // 周波数
                            Text(String(format: "%.3f", row.frequency))
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(row.isHighlighted ? Color.cyan : .white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .frame(height: 30)
                        .padding(.horizontal, 16)
                        .background(
                            row.isHighlighted
                                ? Color(red: 0.05, green: 0.15, blue: 0.2)
                                : Color(red: 0.08, green: 0.08, blue: 0.12)
                        )
                    }
                }
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        }
    }
}

// MARK: - FrequencyRow

private struct FrequencyRow: Identifiable {
    let id = UUID()
    let fingeringName: String
    let japaneseName: String
    let frequency: Double
    let westernName: String
    let isHighlighted: Bool

    init(_ fingeringName: String, _ japaneseName: String, _ frequency: Double, _ westernName: String, isHighlighted: Bool = false) {
        self.fingeringName = fingeringName
        self.japaneseName = japaneseName
        self.frequency = frequency
        self.westernName = westernName
        self.isHighlighted = isHighlighted
    }
}

// MARK: - ヘッダーテキスト用モディファイア

private extension Text {
    func headerStyle(alignment: Alignment = .leading) -> some View {
        self
            .font(.caption)
            .foregroundStyle(.white.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FrequencyTableScreen()
            .navigationTitle("周波数表")
            .navigationBarTitleDisplayMode(.inline)
    }
    .preferredColorScheme(.dark)
}
