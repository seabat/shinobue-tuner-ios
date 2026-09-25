//
//  TunerHelpView.swift
//  shinobuetuner
//
//  チューナーの使い方を説明するヘルプビュー

import SwiftUI

/// チューナーの使い方を説明するビュー（計測未開始時に表示）
struct TunerHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("使い方")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.leading, 8)

            TabView {
                HelpPage(
                    imageName: "SoloModeHelp",
                    modeColor: Color("SoloMonitoring"),
                    title: "計測(単) — ソロチューニング",
                    description: "「計測(単)」モードを選択し、計測開始ボタンを押してください。篠笛を吹くと、音名とセントが表示されます。メーターが中央（0セント）に近づくようにチューニングしてください。",
                    alphaNotice: nil
                )
                HelpPage(
                    imageName: "EnsembleModeHelp",
                    modeColor: Color("EnsembleMonitoring"),
                    title: "計測(複) — アンサンブルチューニング",
                    description: "「計測(複)」モードを選択し、計測開始ボタンを押してください。カウントダウン後に計測が始まります。複数人が同じ音を吹いたとき、ピッチのまとまりを検出して合奏チューニングを判定します。",
                    alphaNotice: "この機能は改善中です。判定結果はご参考までにお使いください。"
                )
                HelpPage(
                    imageName: "RecordModeHelp",
                    modeColor: Color("Recording"),
                    title: "録音",
                    description: "「録音」モードを選択し、録音開始ボタンを押してください。演奏を m4a ファイルとして保存します。録音が完了するとプレイリストに自動追加されます。",
                    alphaNotice: nil
                )
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
            )
        }
    }
}

// MARK: - HelpPage

private struct HelpPage: View {
    let imageName: String
    let modeColor: Color
    let title: String
    let description: String
    let alphaNotice: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 50)
                .cornerRadius(8)

            Text(title)
                .font(.headline)
                .foregroundStyle(modeColor)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(Color("AssistantText"))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)

            if let notice = alphaNotice {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color("AssistantText"))
                    Text(notice)
                        .font(.caption)
                        .foregroundStyle(Color("AssistantText"))
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

// MARK: - Preview

#Preview {
    TunerHelpView()
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 16)
        .background(Color("AppBackground"))
        .preferredColorScheme(.dark)
}
