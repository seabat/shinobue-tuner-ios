//
//  PitchGraphView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  5秒間のピッチ折れ線グラフ（対数スケール、Canvas描画）

import SwiftUI

/// ピッチグラフビュー（5秒間の折れ線グラフ）
struct PitchGraphView: View {
    let pitchHistory: [PitchSample]
    let currentTime: TimeInterval

    // グラフのHz範囲（一/A4 ～ 五の甲/Eb6）
    private let minHz: Float = 442.0
    private let maxHz: Float = 1260.0

    // グラフに表示する篠笛六本調子の全音符ライン（一 ～ 五の甲）
    private let noteLines: [(freq: Float, label: String)] = [
        (442.0,  "A4"),
        (468.3,  "Bb4"),
        (496.1,  "B4"),
        (525.6,  "C5"),
        (556.9,  "Db5"),
        (590.0,  "D5"),
        (625.1,  "Eb5"),
        (662.3,  "E5"),
        (701.6,  "F5"),
        (743.4,  "Gb5"),
        (787.6,  "G5"),
        (834.4,  "Ab5"),
        (884.0,  "A5"),
        (936.6,  "Bb5"),
        (992.3,  "B5"),
        (1051.3, "C6"),
        (1113.8, "Db6"),
        (1180.0, "D6"),
        (1250.2, "Eb6")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ピッチグラフ（5秒間）")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.leading, 8)

            Canvas { context, size in
                // 左: Hz値ラベル、右: 音名ラベル のエリアを確保
                let leftMargin: CGFloat = 42
                let rightMargin: CGFloat = 38
                // 上下端のラベル（F5/F3）が切れないよう内側に余白を取る
                let verticalPadding: CGFloat = 8
                let graphRect = CGRect(
                    x: leftMargin, y: verticalPadding,
                    width: size.width - leftMargin - rightMargin,
                    height: size.height - verticalPadding * 2
                )

                // 背景
                context.fill(
                    Path(graphRect),
                    with: .color(Color(red: 0.05, green: 0.05, blue: 0.1))
                )

                // 音符の水平ガイドライン
                for line in noteLines {
                    let y = yPosition(hz: line.freq, in: graphRect)
                    guard y >= graphRect.minY && y <= graphRect.maxY else { continue }

                    // ガイドライン
                    let linePath = Path { p in
                        p.move(to: CGPoint(x: graphRect.minX, y: y))
                        p.addLine(to: CGPoint(x: graphRect.maxX, y: y))
                    }
                    context.stroke(
                        linePath,
                        with: .color(.white.opacity(0.1)),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )

                    // Hz値ラベル（左側）
                    let hzText = Text(String(format: "%.0f", line.freq))
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.7))
                    context.draw(
                        hzText,
                        at: CGPoint(x: leftMargin / 2, y: y),
                        anchor: .center
                    )

                    // 音名ラベル（右側）
                    let noteText = Text(line.label)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.7))
                    context.draw(
                        noteText,
                        at: CGPoint(x: size.width - rightMargin / 2, y: y),
                        anchor: .center
                    )
                }

                // ピッチ折れ線グラフ
                drawPitchLine(context: context, graphRect: graphRect)

            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    /// ピッチの折れ線グラフを描画する
    private func drawPitchLine(context: GraphicsContext, graphRect: CGRect) {
        guard pitchHistory.count >= 2 else { return }

        let windowEnd = max(currentTime, 5.0)
        let windowStart = windowEnd - 5.0

        var linePath = Path()
        var started = false

        for sample in pitchHistory {
            guard sample.frequency >= minHz && sample.frequency <= maxHz else {
                started = false
                continue
            }

            let t = sample.time - windowStart
            guard t >= 0 else { continue }

            let x = graphRect.minX + CGFloat(t / 5.0) * graphRect.width
            let y = yPosition(hz: sample.frequency, in: graphRect)

            if !started {
                linePath.move(to: CGPoint(x: x, y: y))
                started = true
            } else {
                linePath.addLine(to: CGPoint(x: x, y: y))
            }
        }

        context.stroke(
            linePath,
            with: .color(.cyan),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }

    /// Hz値をグラフ上のY座標に変換（対数スケール）
    private func yPosition(hz: Float, in rect: CGRect) -> CGFloat {
        // 対数スケールで表示（音楽的に自然）
        let logMin = log2(minHz)
        let logMax = log2(maxHz)
        let logHz = log2(hz)
        let normalized = (logHz - logMin) / (logMax - logMin)
        // Y軸は上が高い音（画面上方）
        return rect.maxY - CGFloat(normalized) * rect.height
    }
}

// MARK: - Preview

#Preview("ピッチあり（レ付近を揺れながら上昇）") {
    // 0〜5秒間、D4（295Hz）付近からE4（331Hz）に向かってサイン波で揺れながら上昇するデータ
    let history: [PitchSample] = stride(from: 0.0, to: 5.0, by: 0.05).map { t in
        let base = 295.0 + (t / 5.0) * 36.0          // D4 → E4 に向かう
        let freq = base + 8.0 * sin(t * 4.0)          // サイン波で揺れ
        return PitchSample(time: t, frequency: Float(freq))
    }
    return PitchGraphView(pitchHistory: history, currentTime: 5.0)
        .frame(height: 240)
        .padding(16)
        .background(Color(red: 0.078, green: 0.078, blue: 0.118))
        .preferredColorScheme(.dark)
}

#Preview("データなし（無音）") {
    PitchGraphView(pitchHistory: [], currentTime: 0)
        .frame(height: 240)
        .padding(16)
        .background(Color(red: 0.078, green: 0.078, blue: 0.118))
        .preferredColorScheme(.dark)
}
