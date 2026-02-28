# ぞめきチューナー — 実装ガイド

## アプリ概要

篠笛６本調子専用のリアルタイムチューナーアプリ。
端末のマイクから音を拾い、ピッチ（Hz）と音階をリアルタイムで表示する。

---

## 要件定義

### チューナー機能要件
- マイクから音声を取得し、ピッチ（Hz）をリアルタイム計測
- 検出した音が正しい周波数からどれだけ離れているかをセント単位で表示
- y軸: ピッチ（Hz）、x軸: 経過時間（5秒幅）の折れ線グラフをリアルタイム表示
- 録音中は無音時でもグラフの時間軸が常に流れ、音が鳴った瞬間に折れ線が描画される

### 録音機能要件
- TunerMainView は「計測モード」と「録音モード」をセグメントで切り替え可能（動作中は切替禁止）
  - 計測モード: ピッチ検出のみ。ボタンは「計測開始」/「計測停止」
  - 録音モード: ピッチ検出 + m4a 録音。ボタンは「録音開始」/「録音停止」
- ファイル名は録音開始日時（例: `2026-02-26_21-30-00.m4a`）
- 録音一覧タブに保存済みファイルを新しい順に一覧表示
- 一覧でファイルをタップすると再生。再生中は下部にコントロールバーを表示
- 再生コントロール: 再生/一時停止、停止（選択解除）、シークバー
- 一覧でスワイプするとファイルを削除可能
- 録音保存後、一覧タブを自動更新する

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
├── shinobuetunerApp.swift
│
├── Domain/
│   ├── Model/
│   │   ├── NoteInfo.swift             # NoteInfo 構造体 + NoteHelper enum
│   │   ├── PitchSample.swift          # ピッチサンプル（時刻 + 周波数）
│   │   └── RecordingFile.swift        # 録音ファイルのドメインモデル
│   ├── Repository/
│   │   ├── PitchRepository.swift      # ピッチ取得 + 録音操作のプロトコル
│   │   ├── RecordingRepository.swift  # 録音ファイル管理のプロトコル
│   │   └── PlaybackRepository.swift   # 音声再生のプロトコル
│   └── UseCase/
│       ├── MonitorPitchUseCase.swift  # ピッチ監視 + 録音開始/停止
│       ├── ManageRecordingsUseCase.swift  # 一覧取得・削除
│       └── PlaybackUseCase.swift      # 再生操作
│
├── Data/
│   ├── DataSource/
│   │   ├── MicrophoneDataSource.swift    # AVAudioEngine + FFT/HPS + AVAudioFile録音
│   │   └── AudioPlayerDataSource.swift   # AVAudioEngine + PlayerNode 再生
│   └── Repository/
│       ├── PitchRepositoryImpl.swift
│       ├── RecordingRepositoryImpl.swift  # Documents ディレクトリへの m4a 保存
│       └── PlaybackRepositoryImpl.swift
│
└── Presentation/
    ├── ViewModel/
    │   ├── TunerViewModel.swift          # ピッチ監視 + 録音制御
    │   └── RecordingListViewModel.swift  # 録音一覧・再生の状態管理
    └── View/
        ├── ContentView.swift             # TabView（チューナー / 録音一覧）
        ├── TunerMainView.swift           # 計測/録音モード切替セグメント付きメイン画面
        ├── PermissionRequestView.swift
        ├── NoteDisplayView.swift
        ├── CentsMeterView.swift
        ├── PitchGraphView.swift
        ├── RecordButton.swift            # 計測/録音モード対応ボタン
        ├── RecordingListView.swift       # 録音一覧画面
        ├── RecordingRowView.swift        # 一覧の各行コンポーネント
        └── PlaybackControlView.swift     # 再生コントロールバー
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
- `startRecording(to url: URL) throws` / `stopRecording()` — 録音操作

**RecordingRepository.swift**（Protocol のみ）
- `fetchAll() -> [RecordingFile]` — 保存済み録音ファイルを新しい順に返す
- `delete(url: URL) throws` — ファイル削除
- `newRecordingURL() -> URL` — 保存先URL生成（ファイル名: `yyyy-MM-dd_HH-mm-ss.m4a`）

**PlaybackRepository.swift**（Protocol のみ）
- `playbackTimePublisher` / `isPlayingPublisher` — 再生状態のパブリッシャー
- `play(url:)` / `pause()` / `resume()` / `stop()`

**MonitorPitchUseCase.swift**
- `MonitorPitchUseCaseProtocol` — ViewModel が依存するインターフェース（録音メソッド含む）
- `MonitorPitchUseCase` — `PitchRepository` に委譲する具体実装

**ManageRecordingsUseCase.swift**
- `fetchAll()` / `delete(recording:)` — 録音一覧取得・削除

**PlaybackUseCase.swift**
- `play(recording:)` / `pause()` / `resume()` / `stop()`

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
- **録音**: `nonisolated(unsafe) var recordingFile: AVAudioFile?` をタップコールバックから直接書き込み
  - `startRecording(to:)` — AVAudioFile（AAC/m4a）を生成して録音開始
  - `stopRecording()` — `recordingFile = nil` でファイルを閉じる

**AudioPlayerDataSource.swift**
- `AVAudioEngine` + `AVAudioPlayerNode` で m4a ファイルを再生
- `play(url:)` — AVAudioSession を `.playback` に設定してファイルを再生
- `pause()` / `resume()` / `stop()`
- `Timer.publish(every: 0.1)` で再生位置を `playbackTimePublisher` にemit
- 再生位置: `playerNode.playerTime(forNodeTime:)` で取得

**PitchRepositoryImpl.swift** / **RecordingRepositoryImpl.swift** / **PlaybackRepositoryImpl.swift**
- 各 Repository プロトコルの具体実装（DataSource に委譲）
- `RecordingRepositoryImpl` は Documents ディレクトリの m4a を列挙し `AVAudioFile` で duration を取得

### Presentation/ViewModel

**TunerViewModel.swift**（`@MainActor final class TunerViewModel: ObservableObject`）

主要 @Published プロパティ:
- `currentPitch: Float` — 現在の周波数（Hz）
- `noteResult: (note: NoteInfo, cents: Float)?` — 最近傍音符とセント偏差
- `pitchHistory: [PitchSample]` — 過去5秒のピッチ履歴
- `currentTime: TimeInterval` — 経過時間（0.05秒タイマーで常時更新）
- `isRunning: Bool` — 計測/録音中フラグ
- `permissionGranted: Bool` — マイク許可フラグ
- `isSavingRecording: Bool` — 録音中フラグ（isRunning とは独立）
- `lastSavedRecording: RecordingFile?` — 最後に保存したファイル（一覧更新トリガー）

主要メソッド:
- `startMonitoring()` — ピッチ検出のみ開始 + `Timer.publish(every: 0.05)` で `currentTime` を常時更新
- `stopMonitoring()` — 停止。`cancellables.removeAll()` でタイマーも自動停止
- `startRecording()` — `startMonitoring()` + `useCase.startRecording(to:)` で録音も開始
- `stopRecording()` — 録音停止 → `stopMonitoring()` → `lastSavedRecording` を更新
- `handleNewPitch(_:)` — 音符変換・pitchHistory 更新（5秒ウィンドウ）。サンプルの時刻は `currentTime` を使用

**グラフ時間軸の設計**:
無音時でも `currentTime` が 0.05秒ごとに進み、グラフの時間軸が常に流れる。
音が鳴ると `PitchSample(time: currentTime, frequency: pitch)` としてその時刻に折れ線が描画される。

**RecordingListViewModel.swift**（`@MainActor final class RecordingListViewModel: ObservableObject`）
- `recordings: [RecordingFile]` — 録音ファイル一覧
- `selectedRecording: RecordingFile?` — 再生中ファイル
- `isPlaying: Bool` / `playbackTime: TimeInterval` — 再生状態
- `loadRecordings()` / `deleteRecording(_:)` / `selectAndPlay(_:)` / `togglePlayPause()` / `stopPlayback()`

### Presentation/View

チューナータブ:
- `ContentView.swift` — `TabView`（チューナー / 録音一覧）のルートView。`TunerViewModel` + `RecordingListViewModel` を `@StateObject` で保有。`onChange(of: lastSavedRecording)` で一覧を自動更新
- `TunerMainView.swift` — 上部に計測/録音モード切替セグメント付きのメイン画面
- `PermissionRequestView.swift` — マイク未許可時の権限要求画面
- `NoteDisplayView.swift` — 音名（日本語・西洋）と周波数の大きな表示
- `CentsMeterView.swift` — セントメーター（-50〜+50、カラーグラデーション）
- `PitchGraphView.swift` — 5秒間のピッチ折れ線グラフ（Canvas描画、対数スケール）
- `RecordButton.swift` — `isRecordingMode` でラベルを切り替え（計測開始/停止 or 録音開始/停止）

録音一覧タブ:
- `RecordingListView.swift` — 録音一覧（空状態表示、スワイプ削除）。下部に `PlaybackControlView`
- `RecordingRowView.swift` — ファイル名（拡張子なし）・録音時間・サイズを表示
- `PlaybackControlView.swift` — シークバー + 再生/一時停止 + 停止ボタン

UIのポイント:
- セントメーター: ±10セントが緑、±25セントが黄、それ以上が赤
- ピッチグラフ: 対数スケール（音楽的に均等な間隔）、各音符の水平ガイドライン表示
- テーマ: ダーク（背景 `#14141E` 系）

### スレッド安全性の方針

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` により全型がデフォルト `@MainActor`。

- `detectPitch` は `nonisolated static func` でバックグラウンド実行OK
- タップコールバック → `Task { @MainActor [weak self] in subject.send(pitch) }` でメインに切り替え
- `TunerViewModel` の `sink` 内 → subject.send が MainActor から呼ばれるため受信も MainActor 上
- `MicrophoneDataSource.recordingFile` は `nonisolated(unsafe) var` として宣言し、タップコールバック（バックグラウンドスレッド）から直接 `AVAudioFile.write(from:)` を呼ぶ

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
| シ/B3 | 248.064 | | |
| ド/C4 | 262.815 | | |
| レ/D4 | 295.000 | | |
| ミ/E4 | 331.126 | | |
| ファ/F4 | 350.816 | | |
| ソ/G4 | 393.777 | | |

---

## 今後の改善候補

- Beethoven ライブラリの導入（より高精度なピッチ検出）
- 音量（dB）メーターの追加
- 他の調子（本数）への対応（基準周波数の切り替え）
- 再生中に篠笛のピッチ解析をリアルタイム表示（再生モードのチューナー連携）
- 録音ファイルの共有（Share Sheet）

---

## VS Code 開発環境

### 必要な拡張機能（`.vscode/extensions.json` に定義済み）

| 拡張機能 ID | 用途 |
|---|---|
| `swiftlang.swift-lang` | コード補完・定義ジャンプ（SourceKit-LSP） |
| `sweetpad.sweetpad` | iOS シミュレーターでのビルド・実行・デバッグ |

### 初回セットアップ手順

```bash
# 依存ツール
brew install xcode-build-server xcbeautify

# SourceKit-LSP 用設定ファイルを生成（プロジェクトルートで実行）
xcode-build-server config -project shinobuetuner.xcodeproj -scheme shinobuetuner
```

`buildServer.json` が生成される。これはローカル環境固有のファイルのため git 管理対象外。

### VS Code の設定ファイル一覧（`.vscode/`）

| ファイル | 用途 |
|---|---|
| `settings.json` | Swift 拡張のパス設定 |
| `extensions.json` | 推奨拡張機能の定義 |
| `tasks.json` | `xcodebuild` によるビルドタスク |
| `launch.json` | SweetPad デバッグ起動設定 |
