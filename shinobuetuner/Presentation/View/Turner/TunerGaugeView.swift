//
//  TunerGaugeView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  タコメーター型のチューナーゲージ（-50〜+50セント・半円アーク・カラーグラデーション）

import SwiftUI

/// タコメーター型チューナーゲージ
/// 周波数行（上）＋ 半円アーク・針・目盛り・中央テキスト（下）で自己完結する
struct TunerGaugeView: View {
    /// 最近傍の音符情報とセント偏差。音域外・無音時は nil
    let noteResult: (note: NoteInfo, cents: Float)?
    /// 表示する階名（設定の移動ド／固定ドに応じて呼び出し元で決める）
    let solfegeName: String
    /// 現在の周波数（Hz）。無音時は 0
    let currentPitch: Float
    /// ゲージ中央に表示する内容（音階名／運指名）
    let displayMode: GaugeDisplayMode

    // MARK: - 定数

    /// アークの太さ
    private let stroke: CGFloat = 24
    /// 目盛りラベルを置くためにアークの外側に確保する余白
    private let labelMargin: CGFloat = 38
    /// 周波数行の高さ
    private let frequencyRowHeight: CGFloat = 48
    /// 目盛りのセント値
    private let tickCents: [Float] = [-50, -25, 0, 25, 50]
    /// 中央のメイン表示（階名／運指名）の行高さの目安。針の細線区間の算出に使う
    private let mainDisplayHeight: CGFloat = 72
    /// 中央のセント値の行高さ（VStack の spacing を含む）
    private let centsRowHeight: CGFloat = 16
    /// 中央テキストをピボットからどれだけ上に置くか（半径に対する比率）
    private let centerContentRatio: CGFloat = 0.44

    // MARK: - 派生値

    /// 音が検出されているかどうか（アークの明るさ・周波数表示の制御に使う）
    private var isActive: Bool { currentPitch > 0 }

    /// 音階が確定しているかどうか（中央テキスト・針の位置の制御に使う）
    private var hasNote: Bool { noteResult != nil }

    /// -50 〜 +50 にクランプしたセント値
    private var clampedCents: Float {
        (noteResult?.cents ?? 0).clamped(to: -50...50)
    }

    /// 針の回転角（0セント = 真上 = 0°、+50セント = +90°）
    private var needleAngle: Double {
        guard hasNote else { return 0 }
        return Double(clampedCents / 50) * 90
    }

    /// ズレの大きさを表す色（±10以内=緑 / ±25以内=黄 / それ超=赤）
    private var accentColor: Color {
        guard let cents = noteResult?.cents else { return Color("InactiveMode") }
        let absCents = abs(cents)
        if absCents <= 10 { return .green }
        if absCents <= 25 { return .yellow }
        return .red
    }

    /// アークのカラーグラデーション（左右対称：両端が赤、真上が緑）
    /// 旧セントメーターの配分（赤橙黄 35% / 黄緑 15% / 緑黄 15% / 黄橙赤 35%）をそのまま角度に移植する
    private var arcGradient: AngularGradient {
        AngularGradient(
            stops: [
                .init(color: .red,    location: 0.0),
                .init(color: .orange, location: 0.175),
                .init(color: .yellow, location: 0.35),
                .init(color: .green,  location: 0.50),
                .init(color: .yellow, location: 0.65),
                .init(color: .orange, location: 0.825),
                .init(color: .red,    location: 1.0)
            ],
            center: .center,
            // 0° = 3時方向・時計回り。180°(9時) 〜 360°(3時) で上半分を覆う
            startAngle: .degrees(180),
            endAngle: .degrees(360)
        )
    }

    // MARK: - 本体

    var body: some View {
        VStack(spacing: 0) {
            frequencyRow
                .frame(height: frequencyRowHeight)

            GeometryReader { geo in
                let radius = gaugeRadius(in: geo.size)
                // 針の回転中心。下端から少し上に置く
                let pivot = CGPoint(x: geo.size.width / 2, y: geo.size.height - 8)

                ZStack {
                    arc(radius: radius, pivot: pivot)
                    ticks(radius: radius, pivot: pivot)
                    needle(radius: radius, pivot: pivot)
                    pivotDot(at: pivot)
                    centerContent(radius: radius, pivot: pivot)
                }
            }
        }
    }

    // MARK: - 周波数行

    @ViewBuilder
    private var frequencyRow: some View {
        if hasNote && isActive {
            Text(String(format: "%.1f Hz", currentPitch))
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
        } else {
            // 無音時も高さを保つ
            Color.clear
        }
    }

    // MARK: - ゲージの各要素

    /// 使える幅・高さからアーク中心線の半径を決める
    private func gaugeRadius(in size: CGSize) -> CGFloat {
        let byWidth  = size.width / 2 - labelMargin
        let byHeight = size.height - 8 - labelMargin
        return max(min(byWidth, byHeight), 1)
    }

    /// 半円アーク（上半分）
    private func arc(radius: CGFloat, pivot: CGPoint) -> some View {
        Circle()
            .trim(from: 0.5, to: 1.0)   // 9時 → 12時 → 3時（上半分）
            .stroke(arcGradient, style: StrokeStyle(lineWidth: stroke, lineCap: .butt))
            .frame(width: radius * 2, height: radius * 2)
            .position(pivot)
            .opacity(isActive ? 1.0 : 0.3)
    }

    /// 目盛り線とラベル
    private func ticks(radius: CGFloat, pivot: CGPoint) -> some View {
        ForEach(tickCents, id: \.self) { cent in
            let angle = Double(cent / 50) * 90
            let radians = angle * .pi / 180
            // 真上を 0° として時計回り。画面座標は y が下向きなので cos を反転する
            let dx = sin(radians)
            let dy = -cos(radians)
            let labelRadius = radius + stroke / 2 + 14

            ZStack {
                // 目盛り線（アークの中心線上に重ねる）
                Capsule()
                    .fill(.white.opacity(0.7))
                    .frame(width: 2, height: 8)
                    .rotationEffect(.degrees(angle))
                    .position(x: pivot.x + radius * dx, y: pivot.y + radius * dy)

                // ラベル
                Text(tickLabel(for: cent))
                    .font(.caption2)
                    .foregroundStyle(cent == 0 ? .white : .white.opacity(0.7))
                    .position(x: pivot.x + labelRadius * dx, y: pivot.y + labelRadius * dy)
            }
        }
    }

    /// 目盛りラベルの文字列（0 は符号なし、それ以外は符号付き）
    private func tickLabel(for cent: Float) -> String {
        cent == 0 ? "0" : String(format: "%+.0f", cent)
    }

    /// 針
    /// 中央のメイン表示（階名／運指名）に重なる区間だけを細く薄くして、文字を読めるようにする。
    /// セント値は細い文字なので太いままの先端が重なってよい（可読性に影響しないため）。
    private func needle(radius: CGFloat, pivot: CGPoint) -> some View {
        // 針先はアークの帯を横切って外縁の少し手前まで伸ばす（タコメーターらしい見た目にするため）
        let length = radius + stroke / 2 - 3
        // 中央テキスト全体の上端からメイン表示の上端・下端をピボットからの距離で求める
        let blockTop = radius * centerContentRatio + (mainDisplayHeight + centsRowHeight) / 2
        let thinTop = min(length, blockTop - centsRowHeight)
        let thinBottom = max(0, blockTop - (mainDisplayHeight + centsRowHeight))
        let color = isActive ? Color.white : Color("InactiveMode").opacity(0.5)

        return VStack(spacing: 0) {
            // 先端（太）: 目盛りを指す部分
            Capsule().fill(color)
                .frame(width: 5, height: max(0, length - thinTop))
            // メイン表示に重なる区間（細）
            Capsule().fill(color.opacity(0.45))
                .frame(width: 2, height: max(0, thinTop - thinBottom))
            // ハブ側（太）
            Capsule().fill(color)
                .frame(width: 5, height: thinBottom)
        }
        .frame(width: 5, height: length)
        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
        .rotationEffect(.degrees(needleAngle), anchor: .bottom)
        .position(x: pivot.x, y: pivot.y - length / 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: needleAngle)
    }

    /// 針の回転中心の円
    private func pivotDot(at pivot: CGPoint) -> some View {
        Circle()
            .fill(isActive ? Color.white : Color("InactiveMode").opacity(0.5))
            .frame(width: 14, height: 14)
            .position(pivot)
    }

    // MARK: - 中央テキスト

    /// アーク内側の中央テキスト（セント値 + メイン表示）
    private func centerContent(radius: CGFloat, pivot: CGPoint) -> some View {
        VStack(spacing: 2) {
            // セント値（メインのすぐ上に控えめに）
            if hasNote {
                // 単位は出さず数値のみ（針と重なる幅を抑えるため）
                Text(String(format: "%+.1f", noteResult?.cents ?? 0))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }

            mainDisplay
        }
        .lineLimit(1)
        .minimumScaleFactor(0.55)
        .frame(width: radius * 1.6)
        .multilineTextAlignment(.center)
        .position(x: pivot.x, y: pivot.y - radius * centerContentRatio)
        .animation(.easeInOut(duration: 0.1), value: noteResult?.note.midiNote)
    }

    /// 中央のメイン表示（設定に応じて 音階名 または 運指名）
    /// 表示方式選択モーダルのサンプルと同じ見た目にするため GaugeMainDisplayView を共用する
    @ViewBuilder
    private var mainDisplay: some View {
        if hasNote {
            GaugeMainDisplayView(
                displayMode: displayMode,
                solfegeName: solfegeName,
                westernName: noteResult?.note.westernName ?? "",
                fingeringName: noteResult?.note.fingeringName ?? "",
                color: accentColor,
                baseSize: 60
            )
        } else {
            VStack(spacing: 4) {
                Text("---")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                Text("音を鳴らしてください")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

// MARK: - Preview

/// プレビュー用の共通ラッパー
private func gaugePreview(
    frequency: Float,
    displayMode: GaugeDisplayMode,
    isSilent: Bool = false
) -> some View {
    let result = isSilent ? nil : NoteHelper.closestNote(for: frequency)
    return TunerGaugeView(
        noteResult: result,
        solfegeName: result.map { NoteHelper.solfegeName(midiNote: $0.note.midiNote, system: .movable, tuning: .rokuHon) } ?? "",
        currentPitch: isSilent ? 0 : frequency,
        displayMode: displayMode
    )
    .frame(height: 223)
    .padding(.horizontal, 24)
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}

#Preview("音階名・チューニング完了（±0）") {
    gaugePreview(frequency: 442.0, displayMode: .noteName)
}

#Preview("音階名・シャープ寄り（+25）") {
    gaugePreview(frequency: 448.5, displayMode: .noteName)
}

#Preview("音階名・フラット寄り（-30）") {
    gaugePreview(frequency: 434.4, displayMode: .noteName)
}

#Preview("運指名・チューニング完了（±0）") {
    gaugePreview(frequency: 442.0, displayMode: .fingering)
}

#Preview("運指名・シャープ寄り（+25）") {
    gaugePreview(frequency: 448.5, displayMode: .fingering)
}

#Preview("無音（非アクティブ）") {
    gaugePreview(frequency: 0, displayMode: .noteName, isSilent: true)
}

// MARK: - ヘルパー拡張

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
