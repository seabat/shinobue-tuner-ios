//
//  RecordingListView.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/26.
//
//  録音ファイル一覧画面

import SwiftUI

/// 録音ファイル一覧画面
struct RecordingListView: View {
    @ObservedObject var viewModel: RecordingListViewModel

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()

            if viewModel.recordings.isEmpty {
                // 空状態の表示
                VStack(spacing: 16) {
                    Image(systemName: "waveform.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("録音ファイルがありません")
                        .font(.body)
                        .foregroundStyle(.gray)
                    Text("チューナー画面で録音を開始してください")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.6))
                }
            } else {
                VStack(spacing: 0) {
                    List {
                        ForEach(viewModel.recordings) { recording in
                            RecordingRowView(
                                recording: recording,
                                isSelected: viewModel.selectedRecording?.id == recording.id,
                                isPlaying: viewModel.isPlaying
                            )
                            .onTapGesture {
                                viewModel.selectAndPlay(recording)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteRecording(recording)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    // 再生コントロールバー（選択中ファイルがある場合のみ）
                    if viewModel.selectedRecording != nil {
                        PlaybackControlView(viewModel: viewModel)
                    }
                }
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.loadRecordings()
        }
    }
}
