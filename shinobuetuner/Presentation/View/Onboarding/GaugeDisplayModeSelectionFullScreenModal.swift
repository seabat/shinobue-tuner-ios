//
//  GaugeDisplayModeSelectionFullScreenModal.swift
//  shinobuetuner
//
//  初回起動時（調子選択のあと）に表示するゲージ表示方式の選択画面

import SwiftUI

/// 初回起動時のゲージ表示方式選択モーダル（自己完結型：内部で ViewModel を保持）
/// 「決定」でのみ閉じる（選択せずに閉じる手段は用意しない）
struct GaugeDisplayModeSelectionFullScreenModal: View {
    @StateObject private var viewModel = GaugeDisplayModeSelectionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // ─── 見出し・説明 ───
                VStack(spacing: 12) {
                    Image(systemName: "gauge.with.needle")
                        .font(.system(size: 60))
                        .foregroundStyle(.cyan)
                        .padding(.bottom, 8)

                    Text("メーターに表示する内容を選んでください")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.top, 48)

                // ─── 表示方式の選択（設定画面と共通）───
                Form {
                    GaugeDisplayModeSection(gaugeDisplayMode: $viewModel.gaugeDisplayMode)
                }
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)

                // ─── 表示イメージ（選択に応じて切り替わる）───
                VStack(spacing: 8) {
                    Text("表示イメージ")
                        .font(.caption)
                        .foregroundStyle(Color("AssistantText"))

                    GaugeMainDisplayView(
                        displayMode: viewModel.gaugeDisplayMode,
                        solfegeName: viewModel.sampleSolfegeName,
                        westernName: viewModel.sampleWesternName,
                        fingeringName: viewModel.sampleFingeringName,
                        // チューニングが合っている状態（緑）のサンプルを見せる
                        color: .green,
                        baseSize: 48
                    )
                    .frame(height: 64)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.06))
                )
                .padding(.horizontal, 32)
                .animation(.easeInOut(duration: 0.15), value: viewModel.gaugeDisplayMode)

                // ─── 補足・決定ボタン ───
                VStack(spacing: 16) {
                    Text("あとから設定で変更できます。")
                        .font(.footnote)
                        .foregroundStyle(Color("AssistantText").opacity(0.7))

                    Button {
                        viewModel.confirm()
                        dismiss()
                    } label: {
                        Text("決定")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GaugeDisplayModeSelectionFullScreenModal()
        .preferredColorScheme(.dark)
}
