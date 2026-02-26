//
//  CentsMeterView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  -50〜+50セントのチューナーメーターとカラーグラデーション表示

import SwiftUI

/// セントメーター（-50〜+50、カラーグラデーション）
struct CentsMeterView: View {
    let cents: Float   // -50 ～ +50
    let isActive: Bool

    /// -50 ～ +50 を 0 ～ 1 に正規化
    private var normalizedPosition: CGFloat {
        guard isActive else { return 0.5 }
        return CGFloat((cents.clamped(to: -50...50) + 50) / 100)
    }

    /// 背景グラデーションバー（赤→黄→緑→黄→赤）
    private func gradientBar(width w: CGFloat, height h: CGFloat) -> some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [.red, .orange, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: w * 0.35)

            LinearGradient(
                colors: [.yellow, .green],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: w * 0.15)

            LinearGradient(
                colors: [.green, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: w * 0.15)

            LinearGradient(
                colors: [.yellow, .orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: w * 0.35)
        }
        .frame(height: h * 0.45)
        .clipShape(Capsule())
        .opacity(isActive ? 1.0 : 0.3)
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height - 24 // ラベル分を引く
                let indicatorX = normalizedPosition * w

                ZStack(alignment: .top) {
                    // 背景グラデーションバー
                    gradientBar(width: w, height: h)

                    // 中央ライン（0セント）
                    Rectangle()
                        .fill(.white.opacity(0.6))
                        .frame(width: 2, height: h * 0.45)

                    // インジケーター三角形
                    ZStack {
                        // アウトライン（視認性向上）
                        Triangle()
                            .fill(.black.opacity(0.5))
                            .frame(width: 22, height: 16)
                        Triangle()
                            .fill(isActive ? .white : .gray.opacity(0.3))
                            .frame(width: 18, height: 13)
                    }
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                    .offset(x: indicatorX - w / 2)
                    .animation(.spring(response: 0.15, dampingFraction: 0.7), value: indicatorX)

                    // 目盛りラベル
                    HStack {
                        Text("-50").font(.caption2).foregroundStyle(.gray)
                        Spacer()
                        Text("-25").font(.caption2).foregroundStyle(.gray)
                        Spacer()
                        Text("0").font(.caption2).foregroundStyle(.white)
                        Spacer()
                        Text("+25").font(.caption2).foregroundStyle(.gray)
                        Spacer()
                        Text("+50").font(.caption2).foregroundStyle(.gray)
                    }
                    .offset(y: h * 0.6)
                }
            }
        }

        // セント値テキスト
        if isActive {
            Text(String(format: "%+.1f セント", cents))
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.gray)
        }
    }
}

/// 三角形シェイプ（インジケーター用）
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        // チューニング完了（±0セント）
        CentsMeterView(cents: 0, isActive: true)
            .frame(height: 90)

        // シャープ寄り（+25セント）
        CentsMeterView(cents: 25, isActive: true)
            .frame(height: 90)

        // フラット寄り（-30セント）
        CentsMeterView(cents: -30, isActive: true)
            .frame(height: 90)

        // 無音（非アクティブ）
        CentsMeterView(cents: 0, isActive: false)
            .frame(height: 90)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
    .background(Color(red: 0.078, green: 0.078, blue: 0.118))
    .preferredColorScheme(.dark)
}

// MARK: - ヘルパー拡張

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
