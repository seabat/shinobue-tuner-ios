//
//  TunerSettingsFullScreenModal.swift
//  shinobuetuner
//
//  チューニング成功判定の設定画面

import SwiftUI

/// チューニング成功判定の設定モーダル（自己完結型：内部で ViewModel を保持）
struct TunerSettingsFullScreenModal: View {
    @StateObject private var viewModel = TunerSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showUnsupportedAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                Form {
                    Section {
                        Picker("調子", selection: $viewModel.settings.tuning) {
                            ForEach(ShinobueTuning.allCases) { tuning in
                                Text(tuning.displayName).tag(tuning)
                            }
                        }
                        .pickerStyle(.wheel)
                        .onChange(of: viewModel.settings.tuning) { _, newValue in
                            if !newValue.isSupported {
                                showUnsupportedAlert = true
                                viewModel.settings.tuning = .rokuHon
                            }
                        }
                    } header: {
                        Text("調子")
                            .foregroundStyle(Color("AssistantText"))
                    } footer: {
                        Text("現在は六本調子のみ対応しています。")
                            .foregroundStyle(Color("AssistantText").opacity(0.7))
                    }
                    .alert("未対応の調子", isPresented: $showUnsupportedAlert) {
                        Button("OK") { }
                    } message: {
                        Text("この調子は近日対応予定です。")
                    }

                    Section {
                        Toggle(isOn: $viewModel.settings.showPitchGraph) {
                            Text("ピッチグラフを表示")
                                .foregroundStyle(.white)
                        }
                        .tint(Color.accentColor)
                    } header: {
                        Text("表示設定")
                            .foregroundStyle(Color("AssistantText"))
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("セント範囲")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("±\(Int(viewModel.settings.centThreshold)) セント")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                            Slider(
                                value: $viewModel.settings.centThreshold,
                                in: 1...50,
                                step: 1
                            )
                            .tint(Color.accentColor)
                            HStack {
                                Text("±1")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                                Spacer()
                                Text("±50")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("成功とみなすセント範囲")
                            .foregroundStyle(Color("AssistantText"))
                    } footer: {
                        Text("ピッチが基準音から ±\(Int(viewModel.settings.centThreshold)) セント以内を「チューニング成功」とみなします。推奨: ソロ ±10セント / アンサンブル ±15セント")
                            .foregroundStyle(Color("AssistantText").opacity(0.7))
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("継続時間")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(String(format: "%.1f 秒", viewModel.settings.durationSeconds))
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                            Slider(
                                value: $viewModel.settings.durationSeconds,
                                in: 0.5...5.0,
                                step: 0.5
                            )
                            .tint(Color.accentColor)
                            HStack {
                                Text("0.5秒")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                                Spacer()
                                Text("5.0秒")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("成功とみなす継続時間")
                            .foregroundStyle(Color("AssistantText"))
                    } footer: {
                        Text("セント範囲内のピッチが \(String(format: "%.1f", viewModel.settings.durationSeconds)) 秒間続いた場合に「チューニング成功」とみなします。推奨: ソロ 1.0秒 / アンサンブル 0.5秒")
                            .foregroundStyle(Color("AssistantText").opacity(0.7))
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("スペクトル幅の閾値")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(String(format: "%.1f ビン", viewModel.settings.ensembleSpectralWidthThreshold))
                                    .foregroundStyle(.green)
                                    .fontWeight(.semibold)
                            }
                            Slider(
                                value: $viewModel.settings.ensembleSpectralWidthThreshold,
                                in: 1.0...20.0,
                                step: 0.5
                            )
                            .tint(.green)
                            HStack {
                                Text("1.0")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                                Spacer()
                                Text("20.0")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                            }
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("安定性スコアの閾値")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(String(format: "%.0f セント", viewModel.settings.ensembleStabilityScoreThreshold))
                                    .foregroundStyle(.green)
                                    .fontWeight(.semibold)
                            }
                            Slider(
                                value: $viewModel.settings.ensembleStabilityScoreThreshold,
                                in: 1.0...30.0,
                                step: 1.0
                            )
                            .tint(.green)
                            HStack {
                                Text("1.0")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                                Spacer()
                                Text("30.0")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("アンサンブル 調整オプション（非推奨）")
                            .foregroundStyle(Color("AssistantText"))
                    } footer: {
                        Text("実機テスト中の値です。変更すると判定が正常に動作しない場合があります。最適値が決まり次第この設定は削除されます。")
                            .foregroundStyle(Color("AssistantText").opacity(0.7))
                    }

                    Section {
                        Button("デフォルトに戻す") {
                            viewModel.settings = TunerSettings()
                        }
                        .foregroundStyle(.orange)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("チューニング設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TunerSettingsFullScreenModal()
        .preferredColorScheme(.dark)
}
