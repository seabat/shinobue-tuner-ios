//
//  ContentView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  ぞめきチューナー - ルートビュー

import SwiftUI

/// アプリのルートビュー（ViewModelを保有する）
struct ContentView: View {
    @StateObject private var viewModel = TunerViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景（ダークテーマ）
                Color(red: 0.08, green: 0.08, blue: 0.12)
                    .ignoresSafeArea()

                if viewModel.permissionGranted {
                    TunerMainView(viewModel: viewModel)
                } else {
                    PermissionRequestView(viewModel: viewModel)
                }
            }
            .navigationTitle("ぞめきチューナー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.10, green: 0.10, blue: 0.16), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            // 起動時にマイク権限を確認
            await viewModel.requestPermission()
        }
    }
}

#Preview {
    ContentView()
}
