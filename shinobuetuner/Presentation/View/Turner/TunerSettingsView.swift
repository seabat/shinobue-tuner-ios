//
//  TunerSettingsView.swift
//  shinobuetuner
//
//  チューニング成功判定の設定画面

import SwiftUI

/// チューニング成功判定の設定モーダル
struct TunerSettingsView: View {
    @ObservedObject var settings: TunerSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showUnsupportedAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.12)
                    .ignoresSafeArea()

                Form {
                    Section {
                        Picker("調子", selection: $settings.tuning) {
                            ForEach(ShinobueTuning.allCases) { tuning in
                                Text(tuning.displayName).tag(tuning)
                            }
                        }
                        .pickerStyle(.wheel)
                        .onChange(of: settings.tuning) { _, newValue in
                            if !newValue.isSupported {
                                showUnsupportedAlert = true
                                settings.tuning = .rokuHon
                            }
                        }
                    } header: {
                        Text("調子")
                            .foregroundStyle(.gray)
                    } footer: {
                        Text("現在は六本調子のみ対応しています。")
                            .foregroundStyle(.gray.opacity(0.7))
                    }
                    .alert("未対応の調子", isPresented: $showUnsupportedAlert) {
                        Button("OK") { }
                    } message: {
                        Text("この調子は近日対応予定です。")
                    }

                    Section {
                        Toggle(isOn: $settings.showPitchGraph) {
                            Text("ピッチグラフを表示")
                                .foregroundStyle(.white)
                        }
                        .tint(.cyan)
                    } header: {
                        Text("表示設定")
                            .foregroundStyle(.gray)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("セント範囲")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("±\(Int(settings.centThreshold)) セント")
                                    .foregroundStyle(.cyan)
                                    .fontWeight(.semibold)
                            }
                            Slider(
                                value: $settings.centThreshold,
                                in: 1...50,
                                step: 1
                            )
                            .tint(.cyan)
                            HStack {
                                Text("±1")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("±50")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("成功とみなすセント範囲")
                            .foregroundStyle(.gray)
                    } footer: {
                        Text("ピッチが基準音から ±\(Int(settings.centThreshold)) セント以内を「チューニング成功」とみなします。")
                            .foregroundStyle(.gray.opacity(0.7))
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("継続時間")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(String(format: "%.1f 秒", settings.durationSeconds))
                                    .foregroundStyle(.cyan)
                                    .fontWeight(.semibold)
                            }
                            Slider(
                                value: $settings.durationSeconds,
                                in: 0.5...5.0,
                                step: 0.5
                            )
                            .tint(.cyan)
                            HStack {
                                Text("0.5秒")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("5.0秒")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("成功とみなす継続時間")
                            .foregroundStyle(.gray)
                    } footer: {
                        Text("セント範囲内のピッチが \(String(format: "%.1f", settings.durationSeconds)) 秒間続いた場合に「チューニング成功」とみなします。")
                            .foregroundStyle(.gray.opacity(0.7))
                    }

                    Section {
                        Button("デフォルトに戻す") {
                            settings.centThreshold = 10.0
                            settings.durationSeconds = 1.0
                            settings.tuning = .rokuHon
                            settings.showPitchGraph = true
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
                        .foregroundStyle(.cyan)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TunerSettingsView(settings: TunerSettings())
        .preferredColorScheme(.dark)
}
