//
//  TunerMainView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
//
//  チューナーのメイン画面（各サブビューを配置する）

import SwiftUI

/// チューナーメインビュー
struct TunerMainView: View {
    @ObservedObject var viewModel: TunerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ─── 音名表示エリア ───
            NoteDisplayView(
                noteResult: viewModel.noteResult,
                currentPitch: viewModel.currentPitch
            )
            .frame(height: 160)
            .padding(.top, 8)

            // ─── チューナーメーター ───
            CentsMeterView(
                cents: viewModel.noteResult?.cents ?? 0,
                isActive: viewModel.currentPitch > 0
            )
            .frame(height: 90)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            // ─── ピッチグラフ（5秒間） ───
            PitchGraphView(
                pitchHistory: viewModel.pitchHistory,
                currentTime: viewModel.pitchHistory.last?.time ?? 0
            )
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // ─── 録音開始/停止ボタン ───
            RecordButton(isRunning: viewModel.isRunning) {
                if viewModel.isRunning {
                    viewModel.stopMonitoring()
                } else {
                    viewModel.startMonitoring()
                }
            }
            .padding(.bottom, 24)
        }
    }
}
