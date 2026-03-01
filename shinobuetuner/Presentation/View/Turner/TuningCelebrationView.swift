//
//  TuningCelebrationView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  ±10セント以内（チューニング成功）を祝うビジュアルエフェクト

import SwiftUI

/// チューニング成功時の花火＋いいね！エフェクト
struct TuningCelebrationView: View {
    /// true: ±10セント以内かつ音あり
    let isInTune: Bool

    @State private var activeParticles: [ParticleConfig] = []
    @State private var thumbsUpVisible = false
    @State private var thumbsUpScale: CGFloat = 0
    @State private var thumbsUpOpacity: Double = 0

    private let particleColors: [Color] = [.yellow, .cyan, .green, .orange, .mint, .pink, .white]

    var body: some View {
        ZStack {
            // ─── 花火パーティクル ───
            ForEach(activeParticles) { config in
                FireworkParticle(config: config)
            }

            // ─── いいね！アイコン ───
            if thumbsUpVisible {
                VStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.6), radius: 14)
                    Text("いいね！")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 6)
                }
                .scaleEffect(thumbsUpScale)
                .opacity(thumbsUpOpacity)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isInTune) { _, newValue in
            if newValue {
                triggerCelebration()
            }
        }
    }

    // MARK: - 内部処理

    private func triggerCelebration() {
        // パーティクルを生成（18方向 × 2層 = 36個）
        var configs: [ParticleConfig] = []
        for i in 0..<18 {
            let baseAngle = Double(i) / 18.0 * 2.0 * .pi
            // 内側の層
            configs.append(ParticleConfig(
                angle: baseAngle + Double.random(in: -0.2...0.2),
                targetDistance: CGFloat.random(in: 55...95),
                color: particleColors.randomElement()!,
                size: CGFloat.random(in: 5...9)
            ))
            // 外側の層
            configs.append(ParticleConfig(
                angle: baseAngle + .pi / 18 + Double.random(in: -0.2...0.2),
                targetDistance: CGFloat.random(in: 100...150),
                color: particleColors.randomElement()!,
                size: CGFloat.random(in: 4...7)
            ))
        }
        activeParticles = configs

        // いいね！アイコンをポップイン
        thumbsUpVisible = true
        withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
            thumbsUpScale = 1.2
            thumbsUpOpacity = 1.0
        }

        // 少し縮ませてから消す
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeInOut(duration: 0.25)) {
                thumbsUpScale = 0.9
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.35)) {
                thumbsUpOpacity = 0
                thumbsUpScale = 0.6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            thumbsUpVisible = false
            activeParticles = []
        }

    }
}

// MARK: - ParticleConfig

/// 花火パーティクルの設定値
private struct ParticleConfig: Identifiable {
    let id = UUID()
    let angle: Double
    let targetDistance: CGFloat
    let color: Color
    let size: CGFloat
}

// MARK: - FireworkParticle

/// 花火の単一パーティクル（onAppear で自律アニメーション）
private struct FireworkParticle: View {
    let config: ParticleConfig

    @State private var distance: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(config.color)
            .frame(width: config.size, height: config.size)
            .offset(
                x: cos(config.angle) * distance,
                y: sin(config.angle) * distance
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.65)) {
                    distance = config.targetDistance
                }
                withAnimation(.easeIn(duration: 0.55).delay(0.3)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview("チューニング成功エフェクト") {
    struct PreviewWrapper: View {
        @State private var inTune = false

        var body: some View {
            ZStack {
                Color(red: 0.078, green: 0.078, blue: 0.118)
                    .ignoresSafeArea()
                TuningCelebrationView(isInTune: inTune)
                Button("発火テスト") { inTune.toggle() }
                    .foregroundStyle(.white)
                    .offset(y: 150)
            }
        }
    }
    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
