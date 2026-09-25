//
//  EnsembleCountdownFullScreenModal.swift
//  shinobuetuner
//
//  アンサンブルモニタリング開始前に表示するカウントダウンモーダル

import SwiftUI

/// アンサンブルモニタリング開始前のカウントダウンモーダル
struct EnsembleCountdownFullScreenModal: View {
    /// 「はい！」表示時に呼ばれるコールバック（TunerMainScreen が startMonitoring() を呼ぶ）
    var onCountdownComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    private struct CountStep {
        let label: String
        let color: Color
        let fontSize: CGFloat
    }
    private let steps: [CountStep] = [
        CountStep(label: "3",    color: .cyan,   fontSize: 120),
        CountStep(label: "2",    color: .green,  fontSize: 120),
        CountStep(label: "1",    color: .orange, fontSize: 120),
        CountStep(label: "はい！", color: .white,  fontSize: 72),
    ]

    @State private var currentStep: Int = 0
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // カウントダウン数字
                let step = steps[currentStep]
                Text(step.label)
                    .font(.system(size: step.fontSize, weight: .bold))
                    .foregroundStyle(step.color)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .id(currentStep)

                Spacer()

                // 常時表示メッセージ
                Text("決めた音をみんなで一緒に吹いてください。\n音が揃ったら成功です！")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
            }
        }
        .task {
            await runCountdown()
        }
    }

    // MARK: - カウントダウンロジック

    /// Task.sleep で各ステップを順次実行し、3→2→1→はい！の間隔を均一にする
    /// 全ステップ共通: スプリング登場 → 0.7s表示 → 0.3sフェードアウト → 計1.0s
    private func runCountdown() async {
        for index in 0..<steps.count {
            let isLast = (index == steps.count - 1)

            // 新ステップの初期状態をリセット（スケールを0から始めて一貫したpop-inにする）
            scale = 0
            opacity = 0
            currentStep = index

            // スプリングで登場（scale 0 → 1.2 → 1.0）
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.2
                opacity = 1
            }
            try? await Task.sleep(nanoseconds: 250_000_000) // 0.25s後にスケールを安定
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                scale = 1.0
            }

            // 「はい！」は短め（0.3s）、それ以外は0.7s表示 → 0.3sフェードアウト
            if isLast {
                // 「はい！」: フェードアウトと同時にコールバック & dismiss
                onCountdownComplete()
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
                dismiss()
            } else {
                // 0.7s表示 → 0.3sフェードアウト → 次のステップへ
                try? await Task.sleep(nanoseconds: 700_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EnsembleCountdownFullScreenModal {
        print("カウントダウン完了")
    }
    .preferredColorScheme(.dark)
}
