//
//  GaugeMainDisplayView.swift
//  shinobuetuner
//
//  チューナーゲージ中央のメイン表示（音階名／運指名）
//  （ゲージ本体と、初回起動時の表示方式選択モーダルのサンプルで共用）

import SwiftUI

/// ゲージ中央のメイン表示
/// 設定に応じて「階名 + 西洋音階名」または「運指名」を表示する
struct GaugeMainDisplayView: View {
    /// 表示する内容（音階名／運指名）
    let displayMode: GaugeDisplayMode
    /// 階名（例: "ド"）
    let solfegeName: String
    /// 西洋音階名（例: "B♭4"）
    let westernName: String
    /// 運指名（例: "一"）。音域外などで無い場合は空文字
    let fingeringName: String
    /// 階名・運指名の文字色（ゲージ本体ではセント量に応じた色を渡す）
    let color: Color
    /// 階名のフォントサイズ。西洋音階名・運指名はこれに比例する
    var baseSize: CGFloat = 60

    var body: some View {
        switch displayMode {
        case .noteName:
            HStack(alignment: .firstTextBaseline, spacing: baseSize * 0.13) {
                Text.note(solfegeName, size: baseSize, weight: .bold, design: .rounded)
                    .foregroundStyle(color)
                Text.note(westernName, size: baseSize * 0.4, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.85))
            }
        case .fingering:
            Text.note(displayedFingeringName, size: baseSize * 0.7, weight: .bold, design: .rounded)
                .foregroundStyle(color)
        }
    }

    /// 運指名（未取得時は「—」）
    private var displayedFingeringName: String {
        fingeringName.isEmpty ? "—" : fingeringName
    }
}

// MARK: - Preview

#Preview("音階名") {
    GaugeMainDisplayView(
        displayMode: .noteName,
        solfegeName: "ド",
        westernName: "B♭4",
        fingeringName: "一",
        color: .green
    )
    .padding()
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}

#Preview("音階名・変化記号あり") {
    GaugeMainDisplayView(
        displayMode: .noteName,
        solfegeName: "ファ♯",
        westernName: "F♯5",
        fingeringName: "四（半）",
        color: .red
    )
    .padding()
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}

#Preview("運指名") {
    GaugeMainDisplayView(
        displayMode: .fingering,
        solfegeName: "ド",
        westernName: "B♭4",
        fingeringName: "一",
        color: .green
    )
    .padding()
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}

#Preview("運指名・最長ケース") {
    GaugeMainDisplayView(
        displayMode: .fingering,
        solfegeName: "ラ♯",
        westernName: "A♭4",
        fingeringName: "筒音（半）",
        color: .yellow
    )
    .padding()
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}
