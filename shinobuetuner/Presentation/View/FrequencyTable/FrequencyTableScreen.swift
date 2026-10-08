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
    @StateObject private var viewModel = FrequencyTableViewModel()

    // 六本調子（A4=442Hz基準）音階周波数表（高い音から順）。階名は MIDI ノート番号から算出
    private let rows: [FrequencyRow] = [
        FrequencyRow("4'",          99, 2500.328, "Eb7"),
        FrequencyRow("3'",          98, 2360.029, "D7"),
        FrequencyRow("2'（半）",    97, 2227.540, "Db7"),
        FrequencyRow("2'",          96, 2102.519, "C7"),
        FrequencyRow("1'（半）",    95, 1984.512, "B6"),
        FrequencyRow("1'",          94, 1873.131, "Bb6", isHighlighted: true),
        FrequencyRow("７",          93, 1768.000, "A6"),
        FrequencyRow("６（半）",    92, 1668.770, "Ab6"),
        FrequencyRow("６",          91, 1575.116, "G6"),
        FrequencyRow("５（半）",    90, 1486.784, "Gb6"),
        FrequencyRow("５",          89, 1403.262, "F6"),
        FrequencyRow("４（半）",    88, 1324.504, "E6"),
        FrequencyRow("４",          87, 1250.164, "Eb6"),
        FrequencyRow("３",          86, 1179.998, "D6"),
        FrequencyRow("２（半）",    85, 1113.770, "Db6"),
        FrequencyRow("２",          84, 1051.260, "C6"),
        FrequencyRow("１（半）",    83,  992.256, "B5"),
        FrequencyRow("１",          82,  936.566, "Bb5"),
        FrequencyRow("七",          81,  884.000, "A5"),
        FrequencyRow("六（半）",    80,  834.385, "Ab5"),
        FrequencyRow("六",          79,  787.558, "G5"),
        FrequencyRow("五（半）",    78,  743.352, "Gb5"),
        FrequencyRow("五",          77,  701.631, "F5"),
        FrequencyRow("四（半）",    76,  662.252, "E5"),
        FrequencyRow("四",          75,  625.082, "Eb5"),
        FrequencyRow("三",          74,  589.999, "D5"),
        FrequencyRow("二（半）",    73,  556.885, "Db5"),
        FrequencyRow("二",          72,  525.630, "C5"),
        FrequencyRow("一（半）",    71,  496.128, "B4"),
        FrequencyRow("一",          70,  468.283, "Bb4"),
        FrequencyRow("一（メリ）",  69,  442.000, "A4", isHighlighted: true),
        FrequencyRow("筒音（半）",  68,  417.192, "Ab4"),
        FrequencyRow("筒音",        67,  393.777, "G4"),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ─── 運指表記の凡例 ───
                Text("呂音＝一〜七　甲音＝１〜７　大甲音＝1'〜4'　（半）＝半開孔")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                // ─── 階名の表示方式 ───
                Text(solfegeLegend)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        // ─── ヘッダー行 ───
                        HStack(spacing: 0) {
                            Text("運指").headerStyle()
                            Text("階名").headerStyle()
                            Text("音名").headerStyle()
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

                                // 階名（設定の移動ド／固定ドに従う）
                                Text(viewModel.solfegeName(midiNote: row.midiNote))
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
        // チューナータブで設定が変わる可能性があるため、表示のたびに読み直す
        .onAppear {
            viewModel.reloadSettings()
        }
    }

    /// 階名の表示方式の凡例
    private var solfegeLegend: LocalizedStringResource {
        switch viewModel.solfegeSystem {
        case .movable: return "階名：移動ド（ド＝B♭）"
        case .fixed:   return "階名：固定ド（ド＝C）"
        }
    }
}

// MARK: - FrequencyRow

private struct FrequencyRow: Identifiable {
    let id = UUID()
    let fingeringName: LocalizedStringResource
    let midiNote: Int
    let frequency: Double
    let westernName: String
    let isHighlighted: Bool

    init(_ fingeringName: LocalizedStringResource, _ midiNote: Int, _ frequency: Double, _ westernName: String, isHighlighted: Bool = false) {
        self.fingeringName = fingeringName
        self.midiNote = midiNote
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
