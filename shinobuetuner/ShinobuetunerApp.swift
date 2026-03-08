//
//  ShinobuetunerApp.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//

import SwiftUI

@main
struct ShinobuetunerApp: App {
    @State private var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            if isShowingSplash {
                SplashView()
                    .task {
                        try? await Task.sleep(for: .seconds(1))
                        withAnimation(.easeOut(duration: 0.4)) {
                            isShowingSplash = false
                        }
                    }
            } else {
                ContentView()
            }
        }
    }
}

/// スプラッシュ画面
private struct SplashView: View {
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            Image("LaunchImage")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
        }
    }
}
