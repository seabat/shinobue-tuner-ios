//
//  FrequencyTableScreen.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/03/01.
//
//  篠笛 音階周波数表（選択中の調子に合わせて表示）

import SwiftUI

/// 篠笛の音階周波数表を表示するビュー（調子・階名はチューナーと共通の設定に従う）
struct FrequencyTableScreen: View {
    @StateObject private var viewModel = FrequencyTableViewModel()
    @State private var isSettingsPresented: Bool = false

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
                        ForEach(viewModel.rows) { row in
                            HStack(spacing: 0) {
                                // 運指名
                                Text(row.fingeringName)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(row.isHighlighted ? Color.cyan : .white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // 階名（設定の移動ド／固定ドに従う）
                                Text(row.solfegeName)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(row.isHighlighted ? Color.cyan : .white.opacity(0.85))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // 音名
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
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // ─── 設定ボタン（調子・階名）───
                Button {
                    isSettingsPresented = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color("InactiveMode"))
                }
            }
        }
        // チューナータブで設定が変わる可能性があるため、表示のたびに読み直す
        .onAppear {
            viewModel.reloadSettings()
        }
        // 設定モーダルを閉じたタイミングで設定値を再読み込みする
        .fullScreenCover(isPresented: $isSettingsPresented, onDismiss: {
            viewModel.reloadSettings()
        }) {
            FrequencyTableSettingsFullScreenModal()
        }
    }

    /// 階名の表示方式の凡例（例: "階名：移動ド（ド＝C）"）
    private var solfegeLegend: String {
        switch viewModel.solfegeSystem {
        case .movable:
            return String(format: String(localized: "frequencyTable.legend.movable.format", defaultValue: "階名：移動ド（ド＝%@）"), viewModel.tuning.tonicName)
        case .fixed:
            return String(localized: "階名：固定ド（ド＝C）")
        }
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
    }
    .preferredColorScheme(.dark)
}
