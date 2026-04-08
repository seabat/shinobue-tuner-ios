//
//  PlaybackSettingsFullScreenModal.swift
//  shinobuetuner
//
//  音声ファイル機能の設定画面

import SwiftUI

/// 音声ファイル機能の設定モーダル（自己完結型：内部で ViewModel を保持）
struct PlaybackSettingsFullScreenModal: View {
    @StateObject private var viewModel = PlaybackSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.12)
                    .ignoresSafeArea()

                Form {
                    Section {
                        Picker("並び替え", selection: $viewModel.settings.sortOrder) {
                            ForEach(PlaybackSortOrder.allCases, id: \.self) { order in
                                Text(order.displayName).tag(order)
                            }
                        }
                        .foregroundStyle(.white)
                        .tint(Color.accentColor)
                    } header: {
                        Text("並び替え")
                            .foregroundStyle(Color("AssistantText"))
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("しきい値")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(String(format: "%.3f", viewModel.settings.trimNoisePeakThreshold))
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                            }
                            Slider(
                                value: $viewModel.settings.trimNoisePeakThreshold,
                                in: 0.001...0.020,
                                step: 0.001
                            )
                            .tint(Color.accentColor)
                            HStack {
                                Text("0.001\n(敏感)")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                                    .multilineTextAlignment(.center)
                                Spacer()
                                Text("0.020\n(鈍感)")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AssistantText"))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("頭出し")
                            .foregroundStyle(Color("AssistantText"))
                    } footer: {
                        Text("値が小さいほど微かな音も「有音」と判定します。デフォルト: 0.003")
                            .foregroundStyle(Color("AssistantText").opacity(0.7))
                    }

                    Section {
                        Button("デフォルトに戻す") {
                            viewModel.settings = PlaybackSettings()
                        }
                        .foregroundStyle(.orange)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("音声ファイル設定")
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
    PlaybackSettingsFullScreenModal()
        .preferredColorScheme(.dark)
}
