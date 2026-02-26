# ぞめきチューナー — 実装ガイド

## アプリ概要

篠笛６本調子専用のリアルタイムチューナーアプリ。
端末のマイクから音を拾い、ピッチ（Hz）と音階をリアルタイムで表示する。

---

## 要件定義（アプリ新規作成プロンプト.md より）

### 機能要件
- マイクから音声を取得し、ピッチ（Hz）をリアルタイム計測
- 検出した音が正しい周波数からどれだけ離れているかをセント単位で表示
- y軸: ピッチ（Hz）、x軸: 経過時間（5秒幅）の折れ線グラフをリアルタイム表示

### チューニング設定
- 基準音: **A4 = 442 Hz**（篠笛６本調子）
- 音律: **12平均律**
- 音名表記: 日本語（ドレミファソラシ）と西洋音名（C D E F G A B）を併記

### セント（cent）とは
音程の微細な単位。1オクターブ = 1200セント、半音 = 100セント、**1セント = 半音の1/100**。

```
+50セント → 半音分シャープ（高い）
  0セント → ピッタリ合っている
-50セント → 半音分フラット（低い）
```

計算式: `cents = 1200 × log2(実測周波数 / 基準周波数)`

人間の耳は ±5〜10セント以内のズレを感知しにくいため、このアプリでは以下の判定を採用:
- **±10セント以内** → 緑（チューニング完了）
- **±25セント以内** → 黄（やや外れ）
- **±25セント超**  → 赤（大きくズレ）

---

## 実装アーキテクチャ

**MVVM + Clean Architecture**（Presentation / Domain / Data の3層構成）

### レイヤー概要

```
Presentation ──依存──▶ Domain ◀──依存── Data
```

- **Presentation**（View + ViewModel）: 画面表示と状態管理。Domain のプロトコルにのみ依存
- **Domain**（Model + Repository Protocol + UseCase）: ビジネスロジック。外部依存なし
- **Data**（DataSource + Repository 実装）: AVAudioEngine / FFT などの実装詳細を隠蔽

### ファイル構成

```
shinobuetuner/
├── shinobuetunerApp.swift          # エントリポイント（SwiftDataなし）
├── Item.swift                      # 不使用（空ファイル）
├── ContentView.swift               # 空（Presentation/View/ に移動済み）
├── AudioEngine.swift               # 空（Data/DataSource/ に移動済み）
├── NoteHelper.swift                # 空（Domain/Model/ に移動済み）
│
├── Domain/
│   ├── Model/
│   │   ├── NoteInfo.swift          # NoteInfo 構造体 + NoteHelper enum（442Hz基準変換）
│   │   └── PitchSample.swift       # ピッチサンプル（時刻 + 周波数）
│   ├── Repository/
│   │   └── PitchRepository.swift   # ピッチ取得リポジトリのプロトコル
│   └── UseCase/
│       └── MonitorPitchUseCase.swift  # MonitorPitchUseCaseProtocol + 具体実装
│
├── Data/
│   ├── DataSource/
│   │   └── MicrophoneDataSource.swift  # AVAudioEngine + FFT/HPS ピッチ検出
│   └── Repository/
│       └── PitchRepositoryImpl.swift   # PitchRepository の具体実装
│
└── Presentation/
    ├── ViewModel/
    │   └── TunerViewModel.swift     # @MainActor ObservableObject（状態管理）
    └── View/
        ├── ContentView.swift        # ルートView（@StateObject を保有）
        ├── TunerMainView.swift      # メイン画面レイアウト
        ├── PermissionRequestView.swift  # 権限要求画面
        ├── NoteDisplayView.swift    # 音名・周波数表示
        ├── CentsMeterView.swift     # セントメーター（カラーグラデーション）
        ├── PitchGraphView.swift     # ピッチ折れ線グラフ（Canvas描画）
        └── RecordButton.swift       # 録音開始/停止ボタン
```

### 依存ライブラリ
- **Accelerate**（Xcode組み込み）— FFT計算に使用
- **AVFoundation**（Xcode組み込み）— マイク音声取得に使用
- **Combine** — ピッチの非同期ストリーム（PassthroughSubject / AnyPublisher）
- 外部ライブラリなし（Beethovenは未導入）

---

## 各層の実装内容

### Domain/Model

**NoteInfo.swift**
- `struct NoteInfo` — 音符情報（midiNote / frequency / westernName / japaneseName / octave）
- `enum NoteHelper` — 442Hz基準の周波数計算・音名変換ロジック
  - `closestNote(for:)` — 計測周波数から最近傍の音符とセント偏差を返す
  - セント偏差: `cents = 1200 * log2(実測周波数 / 基準周波数)`
  - 日本語音名テーブル: ド / ド♯ / レ / レ♯ / ミ / ファ / ファ♯ / ソ / ソ♯ / ラ / ラ♯ / シ

**PitchSample.swift**
- `struct PitchSample` — `time: TimeInterval`（セッション開始からの経過秒）+ `frequency: Float`

### Domain/Repository・UseCase

**PitchRepository.swift**（Protocol のみ）
- `pitchPublisher: AnyPublisher<Float, Never>` — ピッチ（Hz）の非同期ストリーム
- `startMonitoring()` / `stopMonitoring()` / `requestPermission() async -> Bool`

**MonitorPitchUseCase.swift**
- `MonitorPitchUseCaseProtocol` — ViewModel が依存するインターフェース
- `MonitorPitchUseCase` — `PitchRepository` に委譲する具体実装

### Data/DataSource・Repository

**MicrophoneDataSource.swift**
- `AVAudioEngine.inputNode` にタップを設置してバッファを受け取る
- **FFT**（高速フーリエ変換）: Accelerate の `vDSP_fft_zrip` / ハン窓 / FFTサイズ 4096
- **HPS**（倍音積スペクトル法）: 倍音数3、基音を正確に検出
- **放物線補間**: サブビン精度の周波数を算出
- 有効音域: 100 Hz ～ 800 Hz / ノイズ判定: RMS < 0.003 で 0 を返す
- `nonisolated static func detectPitch(...)` — バックグラウンドスレッドで安全に実行
- タップコールバック内: `Task { @MainActor [weak self] in subject.send(pitch) }` でメインスレッドに切り替え
- マイク権限: `AVAudioApplication.requestRecordPermission()` (iOS 17+ API)

**PitchRepositoryImpl.swift**
- `PitchRepository` プロトコルの具体実装（`MicrophoneDataSource` に委譲）

### Presentation/ViewModel

**TunerViewModel.swift**（`@MainActor final class TunerViewModel: ObservableObject`）

| プロパティ | 型 | 役割 |
|------------|--------------------------|------------------------|
| `currentPitch` | `@Published Float` | 現在の周波数（Hz） |
| `noteResult` | `@Published (NoteInfo, Float)?` | 最近傍音符とセント偏差 |
| `pitchHistory` | `@Published [PitchSample]` | 過去5秒のピッチ履歴 |
| `isRunning` | `@Published Bool` | 録音中フラグ |
| `permissionGranted` | `@Published Bool` | マイク許可フラグ |

- `init(useCase: any MonitorPitchUseCaseProtocol)` — プロトコルに依存（テスト時にモック注入可能）
- `startMonitoring()` — UseCase.start() + Combine sink → `handleNewPitch()`
- `handleNewPitch(_:)` — 音符変換・pitchHistory 更新（5秒ウィンドウ）

### Presentation/View

| ファイル | 役割 |
|------------------------|----------------------------------------|
| `ContentView.swift` | `@StateObject var viewModel` を保有するルートView |
| `TunerMainView.swift` | `@ObservedObject var viewModel` を受け取るメイン画面 |
| `PermissionRequestView.swift` | マイク未許可時の権限要求画面 |
| `NoteDisplayView.swift` | 音名（日本語・西洋）と周波数の大きな表示 |
| `CentsMeterView.swift` | セントメーター（-50〜+50、カラーグラデーション） |
| `PitchGraphView.swift` | 5秒間のピッチ折れ線グラフ（Canvas描画、対数スケール） |
| `RecordButton.swift` | 録音開始/停止ボタン |

UIのポイント:
- セントメーター: ±10セントが緑、±25セントが黄、それ以上が赤
- ピッチグラフ: 対数スケール（音楽的に均等な間隔）、各音符の水平ガイドライン表示
- テーマ: ダーク（背景 `#14141E` 系）

### スレッド安全性の方針

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` により全型がデフォルト `@MainActor`。

- `detectPitch` は `nonisolated static func` でバックグラウンド実行OK
- タップコールバック → `Task { @MainActor [weak self] in subject.send(pitch) }` でメインに切り替え
- `TunerViewModel` の `sink` 内 → subject.send が MainActor から呼ばれるため受信も MainActor 上

---

## Info.plist 設定

`project.pbxproj` の `GENERATE_INFOPLIST_FILE = YES` を活用し、ビルド設定キーで権限説明を追加:

```
INFOPLIST_KEY_NSMicrophoneUsageDescription = "マイクを使って篠笛の音をリアルタイムで計測します"
```

---

## 周波数・音階表（442Hz基準 12平均律）

| 音名 | 周波数（Hz） | 音名 | 周波数（Hz） |
|------|-------------|------|-------------|
| シ/B2 | 124.032 | ラ/A4 | 442.000 |
| ド/C3 | 131.407 | ラ♯/A♯4 | 468.283 |
| レ/D3 | 147.500 | シ/B4 | 496.128 |
| ミ/E3 | 165.563 | ド/C5 | 525.630 |
| ファ/F3 | 175.408 | レ/D5 | 589.999 |
| ソ/G3 | 196.889 | ミ/E5 | 662.252 |
| ラ/A3 | 221.000 | ファ/F5 | 701.631 |
| ド/C4 | 262.815 | | |
| レ/D4 | 295.000 | | |
| ミ/E4 | 331.126 | | |
| ファ/F4 | 350.816 | | |
| ソ/G4 | 393.777 | | |

---

## 今後の改善候補

- Beethoven ライブラリの導入（より高精度なピッチ検出）
- 音量（dB）メーターの追加
- 録音履歴の保存・再生機能
- 他の調子（本数）への対応（基準周波数の切り替え）
