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
- マイクから音声を取得し、ピッチ（Hz）をリアルタイム計測
- 音階名・周波数を大きく表示
- セントメーターでチューニングのズレを視覚化（±10cent: 緑 / ±25cent: 黄 / それ以上: 赤）
- セント値をメーターバーの上にリアルタイム表示
- チューニング成功時のエフェクト表示
- 5秒間のピッチ推移を折れ線グラフで表示（対数スケール・無音時も時間軸が流れる）
- **30秒間無音が続くと自動的に停止**（計測モード・録音モード共通）

### 録音機能
- 計測モード / 録音モードをボタンで切り替え
  - **計測モード**: ピッチ検出のみ
  - **録音モード**: ピッチ検出 ＋ m4a 録音
- ファイル名は録音開始日時（例: `2026-02-26_21-30-00.m4a`）

### 録音一覧・再生機能
- 保存済みファイルを新しい順に一覧表示
- タップで再生。再生中は下部にコントロールバーを表示
- 再生コントロール: 再生 / 一時停止 / 停止（選択解除）/ シークバー
- スワイプでファイルを削除
- ファイルのリネーム・共有（Share Sheet）
- 録音保存後、一覧を自動更新

### 周波数表
- 篠笛六本調子の全音程（筒音 442 Hz 〜 4'/Eb7 2500 Hz）の周波数一覧表を内蔵

| 運指 | 日本音階名 | 西洋音階名 | 周波数（Hz） |
|---|---|---|---|
| 4' | ファ | Eb7 | 2500.328 |
| 3' | ミ | D7 | 2360.029 |
| 2'（半） | レ♯ | Db7 | 2227.540 |
| 2' | レ | C7 | 2102.519 |
| 1'（半） | ド♯ | B6 | 1984.512 |
| 1' | ド | Bb6 | 1873.131 |
| ７ | シ | A6 | 1768.000 |
| ６（半） | ラ♯ | Ab6 | 1668.770 |
| ６ | ラ | G6 | 1575.116 |
| ５（半） | ソ♯ | Gb6 | 1486.784 |
| ５ | ソ | F6 | 1403.262 |
| ４（半） | ファ♯ | E6 | 1324.504 |
| ４ | ファ | Eb6 | 1250.164 |
| ３ | ミ | D6 | 1179.998 |
| ２（半） | レ♯ | Db6 / C#6 | 1113.770 |
| ２ | レ | C6 | 1051.260 |
| １（半） | ド♯ | B5 | 992.256 |
| １ | ド | Bb5 | 936.566 |
| 七 | シ | A5 | 884.000 |
| 六（半） | ラ♯ | Ab5 / G#5 | 834.385 |
| 六 | ラ | G5 | 787.558 |
| 五（半） | ソ♯ | Gb5 / F#5 | 743.352 |
| 五 | ソ | F5 | 701.631 |
| 四（半） | ファ♯ | E5 | 662.252 |
| 四 | ファ | Eb5 | 625.082 |
| 三 | ミ | D5 | 589.999 |
| 二（半） | レ♯ | Db5 / C#5 | 556.885 |
| 二 | レ | C5 | 525.630 |
| 一（半） | ド♯ | B4 | 496.128 |
| 一 | ド | Bb4 | 468.283 |
| 筒音 | シ | A4（基準音） | 442.000 |

### チューニング設定
- **調子**: ホイールピッカーで選択（現在は六本調子のみ対応）
- **ピッチグラフ表示**: On/Off を切り替え可能
- **セント範囲**: チューニング成功とみなす許容範囲（±1〜±50 セント）
- **継続時間**: 成功とみなすピッチ持続時間（0.5〜5.0 秒）
- 設定はすべて UserDefaults に保存され、次回起動時も維持される

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
│   ├── Model/               # NoteInfo, PitchSample, TunerSettings など
│   ├── Repository/          # Repository プロトコル
│   └── UseCase/             # MonitorPitchUseCase, ManageRecordingsUseCase など
├── Data/                    # AVAudioEngine / FFT などの実装詳細
│   ├── DataSource/          # MicrophoneDataSource, AudioPlayerDataSource
│   └── Repository/          # Repository プロトコルの具体実装
└── Presentation/            # 画面表示と状態管理
    ├── ViewModel/           # TunerViewModel, RecordingListViewModel
    └── View/
        ├── Turner/          # チューナー画面（TunerMainView, CentsMeterView など）
        ├── Recording/       # 録音一覧・再生画面
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
