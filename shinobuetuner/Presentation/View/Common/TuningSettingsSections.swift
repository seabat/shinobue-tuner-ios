//
//  TuningSettingsSections.swift
//  shinobuetuner
//
//  「調子」「階名」の設定セクション（チューニング設定・周波数表設定の両モーダルで共用）

import SwiftUI

/// 調子を選ぶ設定セクション（未対応の調子を選ぶとアラートを出して直前の調子に戻す）
struct TuningPickerSection: View {
    @Binding var tuning: ShinobueTuning
    @State private var showUnsupportedAlert = false

    var body: some View {
        Section {
            Picker("調子", selection: $tuning) {
                ForEach(ShinobueTuning.allCases) { tuning in
                    Text(tuning.displayName).tag(tuning)
                }
            }
            .pickerStyle(.wheel)
            .onChange(of: tuning) { oldValue, newValue in
                if !newValue.isSupported {
                    showUnsupportedAlert = true
                    tuning = oldValue.isSupported ? oldValue : .rokuHon
                }
            }
        } header: {
            Link(destination: tuningExplainerURL) {
                HStack(spacing: 4) {
                    Text("調子")
                    Image(systemName: "info.circle")
                        .font(.caption2)
                }
            }
            .foregroundStyle(Color("AssistantText"))
        } footer: {
            Text("現在は六本調子・八本調子に対応しています。")
                .foregroundStyle(Color("AssistantText").opacity(0.7))
        }
        .alert("未対応の調子", isPresented: $showUnsupportedAlert) {
            Button("OK") { }
        } message: {
            Text("この調子は近日対応予定です。")
        }
    }

    /// 「調子」の意味を解説する外部サイトのURL（ロケールに応じて日本語/英語のサイトを切り替える）
    private var tuningExplainerURL: URL {
        URL(string: String(localized: "url.tuningExplainer", defaultValue: "https://note.com/fuefukitake4/n/n4f7440595e80"))!
    }
}

/// 階名の表示方式（移動ド／固定ド）を選ぶ設定セクション
struct SolfegeSystemSection: View {
    @Binding var solfegeSystem: SolfegeSystem
    /// 選択中の調子（移動ドの説明に主音の音名を表示するために使う）
    let tuning: ShinobueTuning

    var body: some View {
        Section {
            Picker(selection: $solfegeSystem) {
                ForEach(SolfegeSystem.allCases) { system in
                    Text(system.displayName).tag(system)
                }
            } label: {
                Text("階名")
                    .foregroundStyle(.white)
            }
        } header: {
            Text("階名")
                .foregroundStyle(Color("AssistantText"))
        } footer: {
            Text(String(format: String(localized: "settings.solfege.description.format", defaultValue: "移動ド：%1$@の主音 %2$@ をドとして表示します。固定ド：C をドとして表示します。"), tuning.displayName, tuning.tonicName))
                .foregroundStyle(Color("AssistantText").opacity(0.7))
        }
    }
}
