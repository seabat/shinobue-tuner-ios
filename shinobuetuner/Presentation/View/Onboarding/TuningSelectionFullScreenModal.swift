//
//  TuningSelectionFullScreenModal.swift
//  shinobuetuner
//
//  初回起動時（マイク許可の問い合わせ後）に表示する調子選択画面

import SwiftUI

/// 初回起動時の調子選択モーダル（自己完結型：内部で ViewModel を保持）
/// 「決定」でのみ閉じる（選択せずに閉じる手段は用意しない）
struct TuningSelectionFullScreenModal: View {
    @StateObject private var viewModel = TuningSelectionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // ─── 見出し・説明 ───
                VStack(spacing: 12) {
                    Image(systemName: "tuningfork")
                        .font(.system(size: 60))
                        .foregroundStyle(.cyan)
                        .padding(.bottom, 8)

                    Text("お使いの篠笛の調子を選んでください")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("調子は笛の音の高さを表します。笛の本体や購入時の箱に書かれていることが多いです。わからない場合は、お囃子でよく使われる六本調子を選んでください。")
                        .font(.subheadline)
                        .foregroundStyle(Color("AssistantText"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.top, 48)

                // ─── 調子のドラムロール（設定画面と共通）───
                Form {
                    TuningPickerSection(tuning: $viewModel.tuning)
                }
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)

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
    TuningSelectionFullScreenModal()
        .preferredColorScheme(.dark)
}
