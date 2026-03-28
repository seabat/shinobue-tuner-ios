# 注意事項・非自明な設計メモ

一見わかりにくく、知らないとハマりやすい実装上の落とし穴や、
コードを読むだけでは意図が伝わりにくい設計上の決定事項を記録する。

---

## 基準音

A4 = **442 Hz**（一般的な440 Hzではなく篠笛六本調子専用）、12平均律

## Xcode プロジェクト管理

- `PBXFileSystemSynchronizedRootGroup` を使用 → **フォルダにファイルを追加するだけで自動コンパイル対象**（手動で pbxproj 編集不要）

## スレッド安全性

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — 全型がデフォルト `@MainActor`
- `detectPitch` は `nonisolated static func` でバックグラウンド実行
- タップコールバック → `Task { @MainActor [weak self] in subject.send(pitch) }` でメインスレッドに切り替え
- `MicrophoneDataSource.recordingFile` は `nonisolated(unsafe) var` — タップコールバック（バックグラウンド）から直接 `AVAudioFile.write(from:)` を呼ぶ

## ネストした ObservableObject の再描画

- `TunerMainView` は `viewModel` と `viewModel.settings` の両方を `@ObservedObject` で監視する必要がある
- `settings` の変更だけでは `viewModel` を監視しても再描画されないため、`init` で `ObservedObject(wrappedValue:)` を使って両方をラップする

## UseCase の設計方針

- Fetch/Delete/Rename 系は **`callAsFunction`** パターンを採用（インスタンスを関数として呼び出せる）
- `MonitorPitchUseCase` のみ例外 — start/stop/requestPermission/startRecording/stopRecording と複数の操作を束ねる必要があるため `callAsFunction` 非採用

## グラフ時間軸の設計

- 無音時でも `currentTime` が 0.05秒ごとに進み続けることで、グラフの時間軸が常に流れる
- 音が鳴ると `PitchSample(time: currentTime, frequency: pitch)` として折れ線が描画される
