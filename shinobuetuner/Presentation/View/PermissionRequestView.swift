//
//  PermissionRequestView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  マイク権限が未許可のときに表示する権限要求ビュー

import SwiftUI

/// マイク権限要求ビュー
struct PermissionRequestView: View {
    @ObservedObject var viewModel: TunerViewModel

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundStyle(.cyan)

            VStack(spacing: 12) {
                Text("マイクのアクセスが必要です")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("篠笛の音をリアルタイムで計測するため、\nマイクへのアクセスを許可してください。")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await viewModel.requestPermission()
                }
            } label: {
                Label("マイクの使用を許可", systemImage: "mic.badge.plus")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(32)
    }
}
