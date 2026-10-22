//
//  FrequencyTableSettingsFullScreenModal.swift
//  shinobuetuner
//
//  周波数表の設定画面（調子・階名のみ。保存先はチューナー設定と共通）

import SwiftUI

/// 周波数表の設定モーダル（自己完結型：内部で ViewModel を保持）
/// 調子・階名はチューナーと共通の設定（TunerSettings）として保存される
struct FrequencyTableSettingsFullScreenModal: View {
    @StateObject private var viewModel = TunerSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                Form {
                    TuningPickerSection(tuning: $viewModel.settings.tuning)

                    SolfegeSystemSection(
                        solfegeSystem: $viewModel.settings.solfegeSystem,
                        tuning: viewModel.settings.tuning
                    )

                    Section {
                    } footer: {
                        Text("この設定はチューナーと共通です。")
                            .foregroundStyle(Color("AssistantText").opacity(0.7))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("周波数表の設定")
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
    FrequencyTableSettingsFullScreenModal()
        .preferredColorScheme(.dark)
}
