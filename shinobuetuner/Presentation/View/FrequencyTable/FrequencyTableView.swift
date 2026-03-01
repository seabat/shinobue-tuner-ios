//
//  FrequencyTableView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/03/01.
//
//  篠笛六本調子 音階周波数表

import SwiftUI

/// 篠笛六本調子の音階周波数表を表示するビュー
struct FrequencyTableView: View {

    // 六本調子（シ=442Hz基準）音階周波数表（高い音から順）
    private let rows: [FrequencyRow] = [
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
        FrequencyRow("筒音",     "シ",     442.000, "A4", isReference: true),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

            List {
                // ─── ヘッダー行 ───
                HStack(spacing: 0) {
                    Text("運指").headerStyle()
                    Text("日本").headerStyle()
                    Text("西洋").headerStyle()
                    Text("Hz").headerStyle(alignment: .trailing)
                }
                .listRowBackground(Color(red: 0.12, green: 0.12, blue: 0.18))
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

                // ─── データ行 ───
                ForEach(rows) { row in
                    HStack(spacing: 0) {
                        // 運指名
                        Text(row.fingeringName)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(row.isReference ? Color.cyan : .white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // 日本音階名
                        Text(row.japaneseName)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(row.isReference ? Color.cyan : .white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // 西洋音階名
                        Text(row.westernName)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(row.isReference ? Color.cyan : .white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // 周波数
                        Text(String(format: "%.3f", row.frequency))
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(row.isReference ? Color.cyan : .white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                    .listRowBackground(
                        row.isReference
                            ? Color(red: 0.05, green: 0.15, blue: 0.2)
                            : Color(red: 0.08, green: 0.08, blue: 0.12)
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
    let isReference: Bool

    init(_ fingeringName: String, _ japaneseName: String, _ frequency: Double, _ westernName: String, isReference: Bool = false) {
        self.fingeringName = fingeringName
        self.japaneseName = japaneseName
        self.frequency = frequency
        self.westernName = westernName
        self.isReference = isReference
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
        FrequencyTableView()
            .navigationTitle("周波数表")
            .navigationBarTitleDisplayMode(.inline)
    }
    .preferredColorScheme(.dark)
}
