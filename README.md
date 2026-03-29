# 篠笛チューナー

篠笛６本調子専用のリアルタイムチューナーアプリ（iOS）

---

## 概要

端末のマイクから音を拾い、ピッチ（Hz）と音階をリアルタイムで表示します。
演奏した音が基準周波数からどれだけズレているかをセント単位で視覚的にフィードバックするほか、演奏を録音・再生する機能も備えています。

- 基準音: **A4 = 442 Hz**（篠笛６本調子）
- 音律: **12平均律**
- 音階名表記: 日本（ドレミファソラシ）と西洋音階名（C D E F G A B）を併記

---

## 主な機能

### チューナー機能
- マイクからピッチ（Hz）・音階・セントをリアルタイム表示し、セントメーター・成功エフェクト・5秒ピッチグラフ（表示は設定で On/Off）に対応する。**30秒間無音が続くと自動停止**（計測・録音共通）。
- **ソロモニタリング（計測・単）**: 単旋律向けのチューニング成功判定（許容セント・継続時間は設定で変更）。
- **アンサンブルモニタリング（計測・複）**: 合奏向け。開始前にカウントダウンし、スペクトル幅と安定性を含めた判定を行う。
- **チューニング設定**: 調子・ピッチグラフ表示・成功判定のセント範囲・継続時間・アンサンブル用の調整項目などを変更でき、設定は UserDefaults に保存される。

### 録音機能
- **計測**: ピッチ検出のみ。**録音**: ピッチ検出に加え m4a を保存。モードはボタンで切り替え。
- ファイル名は録音開始日時（例: `2026-02-26_21-30-00.m4a`）。

### プレイリスト機能
- 保存済みファイルを一覧表示し、タップで再生。下部にコントロールバー（再生・一時停止・停止・シーク）を表示。スワイプで削除・リネーム・共有など。
- 録音保存後、一覧を自動更新する。

### 周波数表
- 篠笛六本調子の運指と各音の周波数をアプリ内で一覧できる。

詳細は [docs/specification.md](docs/specification.md) を参照。

---

## スクリーンショット

<p align="center">
  <img src="docs/turning_success.png" width="200" alt="チューナー画面">
  <img src="docs/recordinglist.png" width="200" alt="録音一覧画面">
</p>

---

## 技術スタック

| カテゴリ | 内容 |
|---|---|
| 言語 | Swift |
| UI フレームワーク | SwiftUI |
| 非同期処理 | Combine |
| 音声入力 | AVFoundation (AVAudioEngine) |
| ピッチ検出 | Accelerate (FFT + HPS) |
| 音声録音 | AVAudioFile (AAC/m4a) |
| 音声再生 | AVAudioEngine + AVAudioPlayerNode |
| 外部ライブラリ | なし |

### ピッチ検出アルゴリズム
- **FFT**（高速フーリエ変換）: Accelerate の `vDSP_fft_zrip` / ハン窓 / FFTサイズ 4096
- **HPS**（倍音積スペクトル法）: 倍音数3で基音を正確に検出
- **放物線補間**: サブビン精度の周波数を算出
- 有効音域: **100 Hz 〜 2600 Hz**（大甲音域 4'/Eb7 = 2500 Hz をカバー）
- ノイズ判定: RMS < 0.003 で無音とみなす

---

## アーキテクチャ

**MVVM + Clean Architecture**（Presentation / Domain / Data の3層構成）

```
Presentation ──依存──▶ Domain ◀──依存── Data
```

| 層 | 役割 |
|---|---|
| Presentation | View + ViewModel。画面表示と状態管理。Domain のプロトコルにのみ依存 |
| Domain | Model + Repository Protocol + UseCase。ビジネスロジック。外部依存なし |
| Data | DataSource + Repository 実装。AVAudioEngine / FFT などの実装詳細を隠蔽 |

---

## プロジェクト構造

```
shinobuetuner/
├── shinobuetunerApp.swift
├── Domain/                  # ビジネスロジック（外部依存なし）
│   ├── Model/               # NoteInfo, PitchSample, TunerSettings, PlaybackFile など
│   ├── Repository/          # Repository プロトコル
│   └── UseCase/             # MonitorPitchUseCase, FetchPlaybackFilesUseCase など
├── Data/                    # AVAudioEngine / FFT などの実装詳細
│   ├── DataSource/          # MicrophoneDataSource, AudioPlayerDataSource
│   └── Repository/          # Repository プロトコルの具体実装
└── Presentation/            # 画面表示と状態管理
    ├── ViewModel/           # TunerViewModel, PlaybackListViewModel
    └── View/
        ├── Turner/          # チューナー画面（TunerMainScreen, CentsMeterView など）
        ├── Playback/        # 再生一覧・再生コントロール画面
        └── FrequencyTable/  # 篠笛六本調子 音階周波数表
```

---

## 動作環境

| 項目 | 内容 |
|---|---|
| iOS | 26.0 以上 |
| Xcode | 26.0 以上 |
| 外部依存 | なし（CocoaPods / Swift Package Manager 不要） |
| 必要な権限 | マイク（NSMicrophoneUsageDescription） |

---

## セットアップ

### Xcode で開発する場合

1. リポジトリをクローン

```bash
git clone https://github.com/seabat/shinobue-tuner-ios.git
```

2. Xcode でプロジェクトを開く

```bash
open shinobue-tuner-ios/shinobuetuner.xcodeproj
```

3. ビルド & 実行

- Xcode でターゲットデバイスを選択してビルド（⌘R）
- マイクの使用許可を求めるダイアログが表示されるので「許可」を選択

### VS Code で開発する場合

#### 必要な拡張機能

`.vscode/extensions.json` に推奨拡張機能が定義されています。プロジェクトを VS Code で開くと自動的にインストールを促すポップアップが表示されます。

| 拡張機能 | 用途 |
|---|---|
| [Swift (swiftlang.swift-lang)](https://marketplace.visualstudio.com/items?itemName=swiftlang.swift-lang) | コード補完・定義ジャンプ・リファクタリング |
| [SweetPad (sweetpad.sweetpad)](https://marketplace.visualstudio.com/items?itemName=sweetpad.sweetpad) | iOS シミュレーターでのビルド・実行・デバッグ |

#### 初回セットアップ

```bash
# 依存ツールのインストール
brew install xcode-build-server xcbeautify

# SourceKit-LSP 用の設定ファイルを生成（プロジェクトルートで実行）
xcode-build-server config -project shinobuetuner.xcodeproj -scheme shinobuetuner
```

#### ビルド & 実行

- `Cmd + Shift + B` — ビルド（`Debug`）
- `Cmd + Shift + P` → `SweetPad: Launch App` — シミュレーターで起動

---

## ロードマップ

- 他の調子（本数）への対応（基準周波数の切り替え）
- 音量（dB）メーターの追加
- 再生中に篠笛のピッチ解析をリアルタイム表示（再生モードのチューナー連携）
- Beethoven ライブラリの導入（より高精度なピッチ検出）

---

## ライセンス

MIT License
