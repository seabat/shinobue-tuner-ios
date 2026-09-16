# 英語ローカライズ 実装計画

## ステータス：未実装（2026-09-15 作成）

---

## 概要

篠笛チューナー iOS アプリを日英両対応（ローカライズ）させる。端末のシステム言語設定に応じて日本語 / 英語を自動切替し、既存の日本語ユーザー体験は変更しない。

---

## 確定した方針（grill-me による意思決定）

| 論点 | 決定 |
|---|---|
| 言語対応スコープ | 日英両対応（置き換えではなく追加）。端末言語が日本語ならそのまま日本語表示、それ以外は英語表示 |
| 運指名の英語表記 | 筒音→`Open`、呂音 一〜七→`1`〜`7`、甲音→`K1`〜`K7`、大甲→`K1'`〜`K4'`、（半）→`½`（レジスター接頭辞でローマ字化） |
| 日本音階名の英語表記 | レ/ド/ミ/ファ/ソ/ラ/シ → `Re`/`Do`/`Mi`/`Fa`/`Sol`/`La`/`Ti`（固定ソルフェージュ、"Ti" はSo と聞き間違えないための英語圏慣用表記） |
| 実装方式 | Xcode String Catalog（`.xcstrings`）を採用（Xcode 26 / iOS Deployment Target 26.0 のため利用可能。自動キー抽出・欠落チェックが可能） |
| Domain 層の扱い | `NoteInfo.swift` 等の構造・API は変更せず、文字列の値のみ `String(localized:key:defaultValue:)` に差し替える軽量対応（Clean Architecture 上の厳密なリファクタリングは今回は行わない） |
| 英語版アプリ表示名 | `CFBundleDisplayName` を英語ロケール時 `Shinobue Tuner` に（日本語ロケールは「篠笛チューナー」のまま） |
| 検証方法 | シミュレータを英語ロケール（`-AppleLanguages (en) -AppleLocale en_US`）で起動し、各画面をスクリーンショットで確認 |

---

## 調査結果（現状）

- `Localizable.strings` / `.xcstrings` は現状一切存在せず、全文字列が日本語でハードコード
- `project.pbxproj`: `developmentRegion = en`、`knownRegions = (en, Base)` だが実態は日本語ベース
- `Info.plist`（実ファイル、`INFOPLIST_KEY_*` ではない）に `CFBundleDisplayName`（篠笛チューナー）、`CFBundleTypeName`（音声ファイル）、`NSMicrophoneUsageDescription` が日本語でハードコード
- 日本語ハードコード文字列は `Presentation/View/` 配下ほぼ全ファイルに存在
- `Domain/Model/NoteInfo.swift` に表示専用の日本語データ（`japaneseNoteNames`、`fingeringNoteNames`）がハードコードされている。呂音は漢数字、甲音はアラビア数字（全角）、大甲はアポストロフィ付き数字という独自の書き分けでレジスターを区別している
- `Domain/Model/PlaybackSettings.swift`（`SortOrder` 表示名）、`TunerSettings.swift`（`"\(rawValue)本調子"`）にも表示用日本語文字列あり
- `FrequencyTableScreen.swift` は運指名・日本音階名を `String` としてカスタム初期化子に渡し、`Text(row.fingeringName)` で表示している。**`Text(String)` は verbatim 初期化子でローカライズされないため**、この配列の文字列自体を明示的にローカライズする必要がある
- 日付フォーマットは録音ファイル名生成用の固定フォーマットのみでロケール非依存。表示用の日付/数値ロケール依存処理は無し

---

## 実装内容

### 1. プロジェクト設定変更

- `project.pbxproj`: `developmentRegion` を `en` → `ja` に変更（実態が日本語ベースのため）
- `knownRegions` に `en` を追加: `(ja, en, Base)`

### 2. String Catalog の新規作成

| 操作 | ファイル | 内容 |
|---|---|---|
| 新規作成 | `shinobuetuner/Localizable.xcstrings` | ソース言語 = ja。空カタログとして作成し、ビルド時に自動抽出させる |
| 新規作成 | `shinobuetuner/InfoPlist.xcstrings` | `CFBundleDisplayName`（篠笛チューナー/Shinobue Tuner）、`CFBundleTypeName`（音声ファイル/Audio File）、`NSMicrophoneUsageDescription`（マイク許可説明文の英訳）を登録 |

`PBXFileSystemSynchronizedRootGroup` 配下のため、フォルダに配置するだけで手動 pbxproj 編集は不要。

### 3. Domain/Model の文字列差し替え（構造・API 不変）

| ファイル | 対象 |
|---|---|
| `Domain/Model/NoteInfo.swift` | `japaneseNoteNames`（Do/Re/Mi/Fa/Sol/La/Ti）、`fingeringNoteNames`（Open/1〜7/K1〜K7/K1'〜K4'、半音は½） |
| `Domain/Model/PlaybackSettings.swift` | `SortOrder` の表示名 |
| `Domain/Model/TunerSettings.swift` | `"\(rawValue)本調子"` ラベル |

いずれも値を `String(localized: "key", defaultValue: "既存の日本語文字列")` に置き換える。

### 4. Presentation/View の文字列対応

`Text("日本語リテラル")` は String Catalog 導入後ビルド時に自動抽出されるため基本的に変更不要。**変数経由で `Text(_:)` に渡している箇所**（`Text(String)` は自動ローカライズされない）は明示的に `String(localized:)` 化する。

| ファイル | 対応内容 |
|---|---|
| `FrequencyTable/FrequencyTableScreen.swift` | `rows` 配列の運指名・日本音階名リテラルを `String(localized:defaultValue:)` 化。`navigationTitle("周波数表")` は自動抽出対象 |
| `ContentView.swift` | タブ名（自動抽出対象、変更不要） |
| `Turner/TunerHelpView.swift`, `TunerSettingsFullScreenModal.swift`, `PermissionRequestView.swift`, `NoteDisplayView.swift`, `CentsMeterView.swift`, `EnsembleCountdownFullScreenModal.swift`, `TunerMainScreen.swift`, `TuningCelebrationView.swift`, `TunerModeButton.swift` | リテラルは自動抽出対象。変数経由のものがあれば個別対応 |
| `Playback/PlaybackListScreen.swift`, `PlaybackSettingsFullScreenModal.swift` | 同上 |

### 5. ビルドと翻訳追加

1. `xcodebuild build` 等でビルドを実行し、`Localizable.xcstrings` に日本語キーを自動抽出させる
2. `.xcstrings`（JSON 形式）を直接編集し、抽出された各キーに英語訳を追加

### 6. 検証

1. シミュレータを英語ロケール（`-AppleLanguages (en) -AppleLocale en_US`）で起動
2. チューナー・設定・再生一覧・周波数表・ヘルプの各画面をスクリーンショットで確認。崩れがあれば追加調整
3. 日本語ロケールでも既存表示にデグレがないことを確認

---

## 非変更ファイル・注意点

- `PlaybackFileRepositoryImpl.swift` の `DateFormatter`（`"yyyy-MM-dd_HH-mm-ss"`固定）は内部ファイル名生成用でロケール非依存のため変更不要
- Domain 層のクリーンアーキテクチャ上の厳密な分離（中立識別子化）は今回のスコープ外。将来的にリファクタリングする場合は「Domain は中立識別子を返し、Presentation 層でローカライズ文字列に変換する」設計への移行を検討する
