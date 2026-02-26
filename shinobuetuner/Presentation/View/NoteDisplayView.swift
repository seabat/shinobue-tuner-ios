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
                // 日本語音名（大）
                Text(result.note.japaneseName)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .animation(.easeInOut(duration: 0.15), value: result.note.japaneseName)

                // 西洋音名
                Text(result.note.westernName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))

                // 周波数
                Text(String(format: "%.1f Hz", currentPitch))
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundStyle(.gray)
            } else {
                // 無音時
                Text("---")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.gray.opacity(0.4))

                Text("音を鳴らしてください")
                    .font(.body)
                    .foregroundStyle(.gray.opacity(0.6))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.1), value: noteResult?.note.midiNote)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // チューニング完了（±10セント以内 → 緑）
        NoteDisplayView(
            noteResult: NoteHelper.closestNote(for: 295.5),
            currentPitch: 295.5
        )
        .frame(height: 160)

        Divider().background(.gray.opacity(0.3))

        // シャープ寄り（±25セント以内 → 黄）
        NoteDisplayView(
            noteResult: NoteHelper.closestNote(for: 305.0),
            currentPitch: 305.0
        )
        .frame(height: 160)

        Divider().background(.gray.opacity(0.3))

        // 大きくズレている（±25セント超 → 赤）
        NoteDisplayView(
            noteResult: NoteHelper.closestNote(for: 320.0),
            currentPitch: 320.0
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
