//
//  NoteDisplayView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  音名（日本語・西洋）と周波数を大きく表示するビュー

import SwiftUI

/// 音名表示ビュー
struct NoteDisplayView: View {
    let noteResult: (note: NoteInfo, cents: Float)?
    let currentPitch: Float

    private var accentColor: Color {
        guard let cents = noteResult?.cents else { return .gray }
        let absCents = abs(cents)
        if absCents <= 10 { return .green }
        if absCents <= 25 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(spacing: 6) {
            if let result = noteResult {
                // 篠笛音名（左）・日本語音名（中央・大）・西洋音名（右）を横一列に並べる
                HStack(alignment: .center, spacing: 8) {
                    // 篠笛の音名（例: "一", "七の甲"）。篠笛音域外は非表示
                    noteText(result.note.shinobueName ?? "", size: 28, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.85))

                    // 日本語音名（大・カラー）
                    noteText(result.note.japaneseName, size: 72, weight: .bold, design: .rounded)
                        .foregroundStyle(accentColor)
                        .animation(.easeInOut(duration: 0.15), value: result.note.japaneseName)

                    // 西洋音名（例: "A4", "B♭5"）
                    noteText(result.note.westernName, size: 28, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.85))
                }

                // 周波数
                Text(String(format: "%.1f Hz", currentPitch))
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                // 無音時
                Text("---")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))

                Text("音を鳴らしてください")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.1), value: noteResult?.note.midiNote)
    }

    // MARK: - 内部処理

    /// ♯/♭ を小さく上付きで表示する Text を生成する
    /// - AttributedString を使用（iOS 26 で Text + Text が deprecated のため）
    /// - 記号は本文の50%サイズ・25%分ベースラインを上げて表示
    private func noteText(
        _ text: String,
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design = .default
    ) -> Text {
        let symbolSize = size * 0.50
        let offset = size * 0.25
        var attrStr = AttributedString()
        var buffer = ""
        for char in text {
            if char == "♯" || char == "♭" {
                if !buffer.isEmpty {
                    var part = AttributedString(buffer)
                    part.font = Font.system(size: size, weight: weight, design: design)
                    attrStr.append(part)
                    buffer = ""
                }
                var sym = AttributedString(String(char))
                sym.font = Font.system(size: symbolSize, weight: weight)
                sym.baselineOffset = offset
                attrStr.append(sym)
            } else {
                buffer.append(char)
            }
        }
        if !buffer.isEmpty {
            var part = AttributedString(buffer)
            part.font = Font.system(size: size, weight: weight, design: design)
            attrStr.append(part)
        }
        return Text(attrStr)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // チューニング完了（±10セント以内 → 緑）: 一 = A4 = 442Hz
        NoteDisplayView(
            noteResult: NoteHelper.closestNote(for: 442.0),
            currentPitch: 442.0
        )
        .frame(height: 160)

        Divider().background(.gray.opacity(0.3))

        // やや外れ（±25セント以内 → 黄）: 一 を約+23セントシャープ
        NoteDisplayView(
            noteResult: NoteHelper.closestNote(for: 448.0),
            currentPitch: 448.0
        )
        .frame(height: 160)

        Divider().background(.gray.opacity(0.3))

        // 大きくズレている（±25セント超 → 赤）: 一 を約+50セントシャープ
        NoteDisplayView(
            noteResult: NoteHelper.closestNote(for: 455.0),
            currentPitch: 455.0
        )
        .frame(height: 160)

        Divider().background(.gray.opacity(0.3))

        // 無音
        NoteDisplayView(noteResult: nil, currentPitch: 0)
            .frame(height: 160)
    }
    .background(Color(red: 0.078, green: 0.078, blue: 0.118))
    .preferredColorScheme(.dark)
}
