# 注意事項・非自明な設計メモ

一見わかりにくく、知らないとハマりやすい実装上の落とし穴や、
コードを読むだけでは意図が伝わりにくい設計上の決定事項を記録する。

---

## 基準音

A4 = **442 Hz**（一般的な440 Hzではなく篠笛用）、12平均律。調子によらず共通

## 調子（六本調子・八本調子）の扱い

- 運指は調子によらず共通。各調子の値は **六本調子のデータ（`NoteHelper.fingeringNoteNames` の MIDI 番号）を `ShinobueTuning.semitoneOffset`（八本調子 = +2）だけずらして** 求める。調子ごとの表を直書きしない
- 周波数・MIDI 番号は絶対値で調子に依存しない。調子に依存するのは名称（運指名・音名・階名）だけ
- 音名の ♯/♭ は `ShinobueTuning.westernNoteNames`（調子ごとの12音表）で決める。固定ドの階名はこの音名から作る（E♭ → ミ♭）
- 新しい調子に対応するときは `isSupported` と `westernNoteNames` を追加し、`NoteHelperTuningTests` に比較表を足す
- 調子・階名はチューナー／周波数表の両タブで変更できる（保存先は共通の `TunerSettings`）。両画面とも `onAppear` で `reloadSettings()` する

## 初回起動時の調子選択・メーター表示方式の選択

- 表示判定は `TunerViewModel.requestPermission()` の後（許可・拒否どちらでも）。完了記録 `hasSelectedTuning` は **`TunerSettings` に入れず `OnboardingRepository` に保存** する（「デフォルトに戻す」が `TunerSettings()` で全項目を初期化するため、同居させると再表示されてしまう）
- メーター表示方式の選択も同じ理由で `hasSelectedGaugeDisplayMode` を `OnboardingRepository` に置く。**オンボーディングのフラグを増やすときは必ずこちら**
- 2画面は**連鎖**する。`requestPermission()` で調子が未選択なら調子選択だけを出し、`ContentView` の `onDismiss` から `evaluateGaugeDisplayModeSelection()` を呼んで2枚目を出す。調子が選択済みなら `requestPermission()` から直接2枚目を判定する（既存ユーザーには表示方式の選択だけが出る）

## チューナーゲージ（タコメーター）

- 半円アーク。針の角度は `needleAngle = (cents / 50) * 90`（0セント = 真上 = 0°、+50 = +90°）
- アークは `Circle().trim(from: 0.5, to: 1.0)`。SwiftUI の Circle は3時起点・時計回りなので 0.5〜1.0 が上半分になる
- グラデーションは `AngularGradient(startAngle: 180°, endAngle: 360°)` で左右対称（両端が赤・真上が緑）。配分 `0 赤 / .175 橙 / .35 黄 / .50 緑 / .65 黄 / .825 橙 / 1.0 赤` は旧セントメーターの 35/15/15/35 をそのまま角度に移したもの
- ゲージ中央のメイン表示は `GaugeMainDisplayView` に切り出し、**ゲージ本体と初回起動時の表示方式選択モーダルのサンプルで共用**する（サンプルが実物とズレないようにするため）
- **針は「太 → 細 → 太」の3分割**。中央のメイン表示（階名／運指名）に重なる区間だけ細く薄くして文字を読めるようにする。区間は `centerContentRatio` / `mainDisplayHeight` / `centsRowHeight` から算出するので、**中央テキストのフォントサイズや位置を変えたらこれらの定数も合わせる**こと
  - セント値は細い等幅文字なので、太いままの先端が重なってよい（可読性に影響しない）。代わりに**単位は出さず数値のみ**にして針に当たる幅を抑えている
  - 針を全長そのまま太くすると、英語ロケールで `Sol` `Do` などの階名が縦に分断されて読めなくなる（日本語の1文字の階名では気づきにくい）
- **音階名モードでは運指名が画面に出ない**。Maestro のアサーションで運指名をアンカーにできないので注意（階名だけではオクターブ違いの `ド` = `１` と `1'` を区別できず、運指名モードのフロー `tuner_scale_rokuhon_fingering.yaml` が判別を担う）

## テスト

- `NoteHelperTuningTests` は運指名・階名のローカライズ文字列を検証するため、**日本語ロケールで実行する**: `xcodebuild test -scheme shinobuetuner -destination '...' -testLanguage ja -testRegion JP`

## テスト用の音声ファイル入力

- Debug ビルドでは起動引数 `-UITestAudioFile <ファイル名>` があると、`PitchRepositoryImpl` がマイク（`MicrophoneDataSource`）の代わりに `AudioFileDataSource` を使う（どちらも `PitchDataSource` に準拠）。ファイルはアプリの `Library/UITestAudio/` に置く。Release ビルドには含まれない（`#if DEBUG`）
- テスト用音源は `shinobuetunerTests/Resources/` に置く（`shinobuetuner/` 配下に置くとアプリ本体に同梱されてしまう）。生成は `docs/test/scripts/generate_scale_m4a.sh`。純音だと HPS（倍音の積）で基音を拾えないため、第2・第3倍音を含めて生成している

## Xcode プロジェクト管理

- `PBXFileSystemSynchronizedRootGroup` を使用 → **フォルダにファイルを追加するだけで自動コンパイル対象**（手動で pbxproj 編集不要）

## スレッド安全性

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — 全型がデフォルト `@MainActor`
- `MicrophoneDataSource.detectPitchWithSpectrum`（タップコールバックから呼ぶ本体）と `detectPitch` は `nonisolated static func` でバックグラウンド実行
- タップコールバック → `Task { @MainActor [weak self] in subject.send(pitch) }` でメインスレッドに切り替え
- `MicrophoneDataSource.recordingFile` は `nonisolated(unsafe) var` — タップコールバック（バックグラウンド）から直接 `AVAudioFile.write(from:)` を呼ぶ

## ViewModel の設計ルール

- **ViewModel をネストしない** — ViewModel のプロパティに別の ViewModel を持たせてはならない
- **ViewModel への依存は Screen / Modal の View だけ** — サブコンポーネント（行、ボタン等）は ViewModel を直接参照しない
- **View は原則1つの ViewModel に依存する** — 複数の ViewModel を `@ObservedObject` / `@StateObject` で同時に保持しない
- 設定モーダルは `@StateObject private var viewModel = XxxSettingsViewModel()` で自己完結させる（呼び出し元 View から ViewModel を渡さない）
- 設定変更を呼び出し元 ViewModel に反映する場合は `.fullScreenCover(onDismiss:)` で `viewModel.reloadSettings()` を呼ぶ

## UseCase の設計方針

- Fetch/Delete/Rename 系は **`callAsFunction`** パターンを採用（インスタンスを関数として呼び出せる）
- 例外は複数の操作を束ねる UseCase で、`callAsFunction` 非採用:
  - `MonitorPitchUseCase` — start/stop/requestPermission/startRecording/stopRecording
  - `PlaybackUseCase` — play/pause/resume/stop/seek

## 設定系の標準アーキテクチャパターン

`XxxSettings` 系を追加するときは以下の構成に統一する（`TunerSettings` / `PlaybackSettings` が参考実装）:
- `Domain/Model/XxxSettings.swift` — 純粋なデータ struct（デフォルト値のみ）
- `Domain/Repository/XxxSettingsRepository.swift` — `fetch() -> XxxSettings` / `save(_ settings:)` protocol
- `Data/Repository/XxxSettingsRepositoryImpl.swift` — UserDefaults 実装
- `Domain/UseCase/FetchXxxSettingsUseCase.swift` / `SaveXxxSettingsUseCase.swift` — callAsFunction パターン
- `Presentation/ViewModel/XxxSettingsViewModel.swift` — `@Published var settings: XxxSettings { didSet { saveUseCase(settings) } }`
- 設定項目追加時は struct にフィールドを追加し、Repository の fetch/save を更新するだけで UseCase インターフェイスは変更不要

## グラフ時間軸の設計

- 無音時でも `currentTime` が 0.05秒ごとに進み続けることで、グラフの時間軸が常に流れる
- 音が鳴ると `PitchSample(time: currentTime, frequency: pitch)` として折れ線が描画される
