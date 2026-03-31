# TunerHelpView 実装計画

## ステータス：実装済み（2026-04-01）

---

## 概要

チューナー画面の初期状態（計測未開始）に、チューナーの使い方を説明する `TunerHelpView` を表示する。

---

## 表示条件

| `showPitchGraph` | 計測未開始（`hasStartedMonitoring == false`） | 計測開始後（`hasStartedMonitoring == true`） |
|---|---|---|
| `true` | **TunerHelpView** を表示 | **PitchGraphView** を表示 |
| `false` | **TunerHelpView** を表示 | **TunerHelpView** を表示（常時） |

- `hasStartedMonitoring` は `TunerMainScreen` の `@State` フラグ
- `viewModel.isRunning` が `false → true` に変化したタイミングで `true` に設定する
- `TunerMainScreen` の `.onAppear` で `false` にリセットし、タブを開くたびに TunerHelpView を再表示する

---

## 実装内容

### 追加ファイル

| 操作 | ファイル |
|---|---|
| 新規作成 | `Assets.xcassets/SoloModeHelp.imageset/` |
| 新規作成 | `Assets.xcassets/EnsembleModeHelp.imageset/` |
| 新規作成 | `Assets.xcassets/RecordModeHelp.imageset/` |
| 新規作成 | `Presentation/View/Turner/TunerHelpView.swift` |
| 修正 | `Presentation/View/Turner/TunerMainScreen.swift` |

### TunerHelpView の構成

- タイトル「使い方」（`PitchGraphView` と同スタイル）
- `TabView`（ページスタイル）で 3 モードをスワイプ切替
- 枠線あり（`PitchGraphView` と同じ左右余白 16pt）
- 各ページ構成:
  - 画像（`scaledToFit()`、`maxHeight: 50`）
  - モード名見出し（中央寄せ、モードカラー）
  - 説明テキスト（左寄せ、`AssistantText` カラー）
  - アルファ注記（計測(複)のみ、`⚠️` アイコン付き）

### 説明テキスト

**計測(単) — ソロチューニング**
> 「計測(単)」モードを選択し、計測開始ボタンを押してください。篠笛を吹くと、音名とセントが表示されます。メーターが中央（0セント）に近づくようにチューニングしてください。

**計測(複) — アンサンブルチューニング**
> 「計測(複)」モードを選択し、計測開始ボタンを押してください。カウントダウン後に計測が始まります。複数人が同じ音を吹いたとき、ピッチのまとまりを検出して合奏チューニングを判定します。
>
> ⚠️ この機能は改善中です。判定結果はご参考までにお使いください。

**録音**
> 「録音」モードを選択し、録音開始ボタンを押してください。演奏を m4a ファイルとして保存します。録音が完了するとプレイリストに自動追加されます。

### TunerMainScreen の変更点

1. `@State private var hasStartedMonitoring: Bool = false` を追加
2. ピッチグラフ/Spacer の分岐を変更:

```swift
if viewModel.tunerSettings.showPitchGraph && hasStartedMonitoring {
    PitchGraphView(...)
} else {
    TunerHelpView()
}
```

3. `.onChange(of: viewModel.isRunning)` で `isRunning` が true になったら `hasStartedMonitoring = true` に設定
4. `.onAppear` で `hasStartedMonitoring = false` にリセット

---

## 非変更ファイル

- `ControlBarView.swift` — フラグ管理は TunerMainScreen 側で行うため変更不要
- `TunerViewModel.swift` — `isRunning` の既存プロパティで判断できるため変更不要
