//
//  GaugeDisplayModeSection.swift
//  shinobuetuner
//
//  ゲージ中央の表示内容（音階名／運指名）を選ぶ設定セクション
//  （チューナー設定モーダル・初回起動時の表示方式選択モーダルで共用）

import SwiftUI

/// ゲージ中央に表示する内容（音階名／運指名）を選ぶ設定セクション
struct GaugeDisplayModeSection: View {
    @Binding var gaugeDisplayMode: GaugeDisplayMode

    var body: some View {
        Section {
            Picker(selection: $gaugeDisplayMode) {
                ForEach(GaugeDisplayMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            } label: {
                Text("メーターの表示")
                    .foregroundStyle(.white)
            }
            .pickerStyle(.segmented)
        } header: {
            Text("メーターの表示")
                .foregroundStyle(Color("AssistantText"))
        } footer: {
            Text("音階名：階名と西洋音階名（例: シ・A4）を表示します。運指名：篠笛の運指（例: 一・七の甲）を表示します。")
                .foregroundStyle(Color("AssistantText").opacity(0.7))
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var mode: GaugeDisplayMode = .noteName

    Form {
        GaugeDisplayModeSection(gaugeDisplayMode: $mode)
    }
    .scrollContentBackground(.hidden)
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}
