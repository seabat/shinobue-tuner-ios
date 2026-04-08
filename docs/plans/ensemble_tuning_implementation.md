# アンサンブルモニタリング機能 実装命令文

## Claude Codeへの命令文

以下の仕様で、複数人の篠笛が同じ音程で揃っているかを判定するアンサンブルモニタリング機能を実装してください。

## 用語定義

| 用語 | 概念 |
|---|---|
| **ソロモニタリング** | 1人でピッチを計測するモード（`soloMonitoring`） |
| **アンサンブルモニタリング** | 複数人でピッチを計測するモード（`ensembleMonitoring`） |
| **モニタリング** | ピッチを計測している状態（`startMonitoring()` / `stopMonitoring()`） |
| **チューニング判定** | in-tune かどうかを判定するロジック（`updateInTuneState()` / `handleEnsembleState()`） |
| **チューニング成功** | in-tune 状態が一定時間継続したこと（`showTuningCelebration`） |

---

## チューニング判定条件の比較

| 条件 | ソロ | アンサンブル |
|---|---|---|
| ① セント範囲 | `abs(cents) <= centThreshold` | `abs(centsDeviation) <= centThreshold` |
| ② スペクトル幅 | なし | `spectralWidth <= ensembleSpectralWidthThreshold` |
| ③ 安定性スコア | なし | `stabilityScore <= ensembleStabilityScoreThreshold` |
| 継続時間 | `durationSeconds` 以上継続 | `durationSeconds` 以上継続 |

①と継続時間はソロ・アンサンブル共通で `TunerSettings` の値を使用する。
②③はアンサンブル固有で `TunerSettings` に高難度オプションとして追加する。

---

## 前提条件
- `detectPitch()` メソッド本体は変更しない。内部処理を `detectPitchWithSpectrum()` として再利用する
- 1台の端末・1つのマイクで複数人の音を同時に拾う
- 複数人は必ず同じ音階（同じ音名）を吹くという前提がある
  - 対象音階は自動検出する（事前選択不要）
  - `spectralWidth`（スペクトル幅）と `stabilityScore`（セント標準偏差）の組み合わせで「全員が同じピッチで揃っているか」を判定する
- 新規ファイルを作成して既存コードへの影響を最小限にすること

---

## 実装内容

### 1. MicrophoneDataSource.swift を修正

#### subject の型を変更

`subject` をピッチとスペクトルをセットで流す型に変更する。
これにより tap 内の FFT 計算が1回で済み、`spectrumSubject` を別途追加する必要がなくなる。

```swift
// 変更前
private let subject = PassthroughSubject<Float, Never>()

// 変更後
private let subject = PassthroughSubject<(pitch: Float, magnitudes: [Float]), Never>()
```

#### publisher を後方互換を保ちつつ維持

既存の `pitchPublisher` チェーン（PitchRepository → MonitorPitchUseCase → TunerViewModel）は変更不要。

```swift
// 既存：.map で Float に変換して後方互換を維持
var publisher: AnyPublisher<Float, Never> {
    subject.map { $0.pitch }.eraseToAnyPublisher()
}

// 新規追加：binWidth は固定値のため map で付与する
var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> {
    let binWidth = Float(engine.inputNode.inputFormat(forBus: 0).sampleRate) / Float(4096)
    return subject
        .map { (pitch: $0.pitch, magnitudes: $0.magnitudes, binWidth: binWidth) }
        .eraseToAnyPublisher()
}
```

#### detectPitchWithSpectrum() を追加

既存の `detectPitch()` は一切変更しない。
以下のオーバーロードメソッドを追加する。
内部処理は `detectPitch()` と同じだが、HPSスペクトル計算後の `hpsSpectrum` 配列も一緒に返す。

```swift
nonisolated static func detectPitchWithSpectrum(
    buffer: AVAudioPCMBuffer,
    sampleRate: Float,
    fftSize: Int
) -> (pitch: Float, magnitudes: [Float])
```

#### tap コールバックを修正

`detectPitch()` の呼び出しを `detectPitchWithSpectrum()` に置き換え、結果を `subject.send()` する。
`binWidth` は固定値（`sampleRate / Float(fftSize)`）のため subject には含めず、`spectrumPublisher` の `map` 内で付与する。

```swift
let result = MicrophoneDataSource.detectPitchWithSpectrum(
    buffer: buffer,
    sampleRate: sampleRate,
    fftSize: fftSize
)
Task { @MainActor [weak self] in
    self?.subject.send((pitch: result.pitch, magnitudes: result.magnitudes))
}
```

---

### 2. spectrumPublisher を各層に中継する（PitchRepository → MonitorPitchUseCase）

`TunerViewModel` から `useCase.spectrumPublisher` でアクセスできるよう、各層に1行ずつ追加する。

**PitchRepository プロトコル（Domain/Repository/PitchRepository.swift）**
```swift
var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> { get }
```

**PitchRepositoryImpl（Data/Repository/PitchRepositoryImpl.swift）**
```swift
var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> {
    dataSource.spectrumPublisher
}
```

**MonitorPitchUseCaseProtocol（Domain/UseCase/MonitorPitchUseCase.swift）**
```swift
var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> { get }
```

**MonitorPitchUseCase（Domain/UseCase/MonitorPitchUseCase.swift）**
```swift
var spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never> {
    repository.spectrumPublisher
}
```

---

### 3. AudioConstants に定数を追加（1定数のみ）

既存の `AudioConstants` に以下を追加する。
`spectralWidthThreshold` と `stabilityScoreThreshold` はユーザーが調整できるよう `TunerSettings` に移動するため追加しない。

```swift
static let ensembleBufferSize: Int = 30  // 安定性判定に使うフレーム数（リングバッファサイズ）
```

---

### 4. TunerSettings にアンサンブル用高難度オプションを追加

`Domain/Model/TunerSettings.swift` にアンサンブル固有のフィールドを追加する。

```swift
/// アンサンブル用高難度オプション（非推奨・実機テスト中）
var ensembleSpectralWidthThreshold: Float = 5.0   // スペクトル幅の閾値（ビン数）
var ensembleStabilityScoreThreshold: Float = 10.0  // 安定性スコアの閾値（セント標準偏差）
```

`TunerSettingsFullScreenModal.swift` に以下の Section を追加する。

```
Section header: "アンサンブル 調整オプション（非推奨）"
Section footer: "実機テスト中の値です。変更すると判定が正常に動作しない場合があります。最適値が決まり次第この設定は削除されます。"
```

- **スペクトル幅の閾値**: Slider（範囲 1.0〜20.0、ステップ 0.5）
- **安定性スコアの閾値**: Slider（範囲 1.0〜30.0、ステップ 1.0）

また既存の footer の推奨値テキストも更新する:
- セント範囲 footer: 「推奨: ソロ ±10セント / アンサンブル ±15セント」を追記
- 継続時間 footer: 「推奨: ソロ 1.0秒 / アンサンブル 0.5秒」を追記

---

### 4a. TunerSettingsRepositoryImpl.swift を修正

`Data/Repository/TunerSettingsRepositoryImpl.swift` の `Keys` に新キーを追加し、`fetch()` と `save()` を更新する。

```swift
// Keys に追加
static let ensembleSpectralWidthThreshold  = "ensembleSpectralWidthThreshold"
static let ensembleStabilityScoreThreshold = "ensembleStabilityScoreThreshold"
```

```swift
// fetch() の変数読み込み部分に追加
let savedSpectralWidth  = defaults.double(forKey: Keys.ensembleSpectralWidthThreshold)
let savedStabilityScore = defaults.double(forKey: Keys.ensembleStabilityScoreThreshold)
```

```swift
// fetch() の return TunerSettings(...) に追加（既存フィールドに続けて）
ensembleSpectralWidthThreshold:  savedSpectralWidth  > 0 ? Float(savedSpectralWidth)  : 5.0,
ensembleStabilityScoreThreshold: savedStabilityScore > 0 ? Float(savedStabilityScore) : 10.0
```

```swift
// save() に追加
defaults.set(settings.ensembleSpectralWidthThreshold,  forKey: Keys.ensembleSpectralWidthThreshold)
defaults.set(settings.ensembleStabilityScoreThreshold, forKey: Keys.ensembleStabilityScoreThreshold)
```

---

### 5. EnsembleTuningDetector.swift を新規作成

`spectrumPublisher` を受け取り、
アンサンブルモニタリングのチューニング判定結果を publish するクラス。

#### 出力する構造体・publisher

```swift
struct EnsembleTuningState {
    let detectedFrequency: Float   // 検出周波数 (Hz)
    let centsDeviation: Float      // 基準音からのズレ (セント)
    let spectralWidth: Float       // スペクトル幅（ビン数）：小さいほど揃っている
    let isInTune: Bool             // チューニング成功フラグ
    let stabilityScore: Float      // 安定性スコア（セント標準偏差）
}

// 外部公開用パブリッシャー（TunerViewModel が subscribe する）
var publisher: AnyPublisher<EnsembleTuningState, Never>
```

#### チューニング判定ロジック

直近 `AudioConstants.ensembleBufferSize` フレーム分のセント値をリングバッファで保持し、
以下の3条件がすべて満たされている場合に `isInTune = true` にする。
継続時間チェックは `TunerViewModel.handleEnsembleState()` で行う（`EnsembleTuningDetector` では行わない）。

① `abs(centsDeviation) <= Float(settings.centThreshold)`（`centThreshold` は `Double`、`centsDeviation` は `Float` のため明示キャストが必要）
② `spectralWidth <= settings.ensembleSpectralWidthThreshold`（ピークが鋭い＝全員が揃っている）
③ `stabilityScore <= settings.ensembleStabilityScoreThreshold`（セント標準偏差が閾値以内）

**centsDeviation の計算方法：**
`NoteHelper.closestNote(for: pitch)` の戻り値 `cents` をそのまま使用する。

```swift
let centsDeviation = NoteHelper.closestNote(for: pitch)?.cents ?? 0
```

**stabilityScore の計算方法：**
リングバッファに蓄積した過去 `ensembleBufferSize` フレーム分の `centsDeviation` の標準偏差。

```swift
let mean = buffer.reduce(0, +) / Float(buffer.count)
let variance = buffer.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Float(buffer.count)
let stabilityScore = sqrt(variance)
```

**peakBin の計算方法：**
`spectrumPublisher` から届く `pitch` と `binWidth` を使って算出する。

```swift
let peakBin = max(0, min(Int(pitch / binWidth), magnitudes.count - 1))
```

**spectralWidth の計算方法：**
ピーク最大値に対して振幅比0.5（-6dB）となる左右のビン幅を「スペクトル幅」とする。

```swift
// ピーク付近の -6dB 幅を計算
let threshold = magnitudes[peakBin] * 0.5
var left = peakBin
var right = peakBin
while left > 0 && magnitudes[left] > threshold { left -= 1 }
while right < magnitudes.count - 1 && magnitudes[right] > threshold { right += 1 }
let spectralWidth = Float(right - left)
```

#### start() のシグネチャ

`spectrumPublisher` と `TunerSettings` を受け取る。

```swift
func start(
    spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never>,
    settings: TunerSettings  // centsDeviation・継続時間・スペクトル幅・安定性スコアの閾値に使用
)
```

#### subject.send はメインスレッドで呼ぶ（既存コードと同じパターン）

```swift
Task { @MainActor [weak self] in
    self?.subject.send(state)
}
```

---

### 6. TunerViewModel.swift を修正

#### `fetchSettingsUseCase` を `fetchTunerSettingsUseCase` にリネーム

既存の `private let fetchSettingsUseCase` を `fetchTunerSettingsUseCase` にリネームする（プロパティ名、イニシャライザ引数、呼び出し箇所すべて）。

---

#### TunerMode を TunerViewModel.swift に移動

`TunerMode` は View と ViewModel の両方が参照するため、`TunerViewModel.swift` に定義する。
`TunerMainScreen.swift` からは削除する。

```swift
enum TunerMode: String, CaseIterable {
    case soloMonitoring     = "計測(単)"
    case ensembleMonitoring = "計測(複)"
    case recording          = "録音"
}
```

#### 追加するプロパティ

```swift
/// 現在のチューナーモード（View から設定される）
@Published var tunerMode: TunerMode = .soloMonitoring

/// EnsembleTuningDetector のインスタンス
private var ensembleDetector: EnsembleTuningDetector? = nil
```

`tunerMode` は排他的なので、チューニング成功エフェクトはソロ・アンサンブル共通で既存の `showTuningCelebration` を流用する。新たなフラグは追加しない。

#### updateInTuneState() のシグネチャを変更

solo 側で行っていた `isInTune` の計算（`abs(cents) <= centThreshold`）をメソッド内から呼び出し側に移し、`isInTune: Bool` を受け取るシグネチャに変更する。これにより ensemble からも共用できる。

```swift
// 変更前
private func updateInTuneState(midiNote: Int, cents: Float)

// 変更後
private func updateInTuneState(midiNote: Int, isInTune: Bool)
```

solo からの呼び出し（`handleNewPitch()` 内）:

```swift
let isInTune = abs(r.cents) <= Float(tunerSettings.centThreshold)
updateInTuneState(midiNote: r.note.midiNote, isInTune: isInTune)
```

#### handleNewPitch() を修正

`pitchPublisher` の subscribe はすべてのモードで必要（`currentPitch`、`noteResult`、`pitchHistory`、無音タイムアウトの更新のため）。
ただし、チューニング成功判定（`updateInTuneState`）はソロモニタリング時のみ呼ぶ。

```swift
// handleNewPitch() 内のチューニング判定部分をすべて tunerMode でガード
// （resetInTuneState() も showTuningCelebration = false を呼ぶため、アンサンブルモードで誤って消えないよう保護）
if tunerMode == .soloMonitoring {
    if pitch > 0 {
        if let r = result {
            let isInTune = abs(r.cents) <= Float(tunerSettings.centThreshold)
            updateInTuneState(midiNote: r.note.midiNote, isInTune: isInTune)
        } else {
            resetInTuneState()
        }
    } else {
        resetInTuneState()
    }
}
```

#### startMonitoring() を修正

`tunerMode == .ensembleMonitoring` のとき、
`EnsembleTuningDetector` を起動して `publisher` を subscribe する。

```swift
if tunerMode == .ensembleMonitoring {
    let detector = EnsembleTuningDetector()
    detector.start(
        spectrumPublisher: useCase.spectrumPublisher,
        settings: fetchTunerSettingsUseCase()
    )
    detector.publisher
        .sink { [weak self] state in
            self?.handleEnsembleState(state)
        }
        .store(in: &cancellables)
    ensembleDetector = detector
}
```

#### handleEnsembleState() を追加

`EnsembleTuningDetector` からフレームごとに `isInTune`（3条件の瞬時判定）が届く。
`updateInTuneState(midiNote:isInTune:)` を共用するため、1行で済む。
`midiNote` は ensemble では音名変化の追跡に使わないためダミー値 `0` を渡す。

```swift
private func handleEnsembleState(_ state: EnsembleTuningState) {
    updateInTuneState(midiNote: 0, isInTune: state.isInTune)
}
```

#### stopMonitoring() を修正

```swift
ensembleDetector = nil
// inTuneState は既存の resetInTuneState() でリセットされるため追加不要
```

---

### 7. TuningCelebrationView.swift は変更不要

`TuningCelebrationView` は `isInTune: Bool` を受け取る汎用Viewなので変更しない。
ソロ・アンサンブルどちらのモードでも同じ `showTuningCelebration` を使うため、呼び出し箇所も増やさない。

```swift
// ソロ・アンサンブル共通（変更なし）
TuningCelebrationView(isInTune: viewModel.showTuningCelebration)
```

---

### 8. EnsembleCountdownFullScreenModal.swift を新規作成

アンサンブルモニタリング開始前に表示するカウントダウンモーダル。

#### 表示内容

- **メッセージ**: 「決めた音をみんなで一緒に吹いてください。音が揃ったら成功です！」（カウントダウン中も下部に常時表示）
- **カウントダウン**: `3` → `2` → `1` → `はい！`（各1秒）

#### アニメーション仕様

| 表示 | カラー | アニメーション |
|---|---|---|
| `3` | `.cyan` | スプリングで登場（scale 0 → 1.2 → 1.0）、1秒後フェードアウト |
| `2` | `.green` | 同上 |
| `1` | `.orange` | 同上 |
| `はい！` | `.white` | スプリング登場後、パルス（scale 1.0 → 1.1 → 1.0） |

背景は既存の濃紺（`Color(red: 0.08, green: 0.08, blue: 0.12)`）。
数字のフォントサイズは 120、太字。

#### 発火タイミング

```
「はい！」表示と同時に → onCountdownComplete() コールバックを呼ぶ
  → TunerMainScreen が viewModel.startMonitoring() を呼び出す
1秒後 → Modal 内部で @Environment(\.dismiss) を呼んで自己 dismiss
```

`TunerMainScreen` は `showEnsembleCountdown = true` でモーダルを表示するが、`false` に戻す処理は不要。Modal が `@Environment(\.dismiss)` で自己 dismiss すると `isPresented` バインディングが自動的に `false` になる（`TunerSettingsFullScreenModal` と同じパターン）。

#### シグネチャ

```swift
struct EnsembleCountdownFullScreenModal: View {
    var onCountdownComplete: () -> Void  // 「はい！」表示時に呼ばれる
    @Environment(\.dismiss) private var dismiss
}
```

---

### 9. TunerMainScreen.swift を修正

#### TunerMode の定義を削除

`TunerMode` は `TunerViewModel.swift` に移動するため、`TunerMainScreen.swift` から削除する。

#### 追加・変更するプロパティ

```swift
// selectedMode の初期値を変更
@State private var selectedMode: TunerMode = .soloMonitoring  // .monitoring から変更

// 追加
@State private var showEnsembleCountdown: Bool = false
```

#### onChange・fullScreenCover を追加

`selectedMode` の変化を `viewModel.tunerMode` に反映し、アンサンブルカウントダウンモーダルを表示する。

```swift
// TunerMainScreen の body に追加
.onChange(of: selectedMode) { _, newMode in
    viewModel.tunerMode = newMode
}
.fullScreenCover(isPresented: $showEnsembleCountdown) {
    EnsembleCountdownFullScreenModal {
        // カウントダウン完了コールバック
        viewModel.startMonitoring()
    }
}
```

ボタンタップ時のアクション（switch 文）は Section 10 ControlBarView に記載。`showEnsembleCountdown` は `@Binding` として ControlBarView に渡す。

#### PreviewUseCase に `spectrumPublisher` を追加

Section 2 参照。

---

### 10. ControlBarView.swift を修正

#### RecordButton の呼び出しを変更（`isRecordingMode: Bool` → `accentColor: Color`）

```swift
RecordButton(
    isRunning: viewModel.isRunning,
    accentColor: accentColor(for: selectedMode)
) {
    switch selectedMode {
    case .soloMonitoring:
        viewModel.isRunning ? viewModel.stopMonitoring() : viewModel.startMonitoring()
    case .ensembleMonitoring:
        if viewModel.isRunning {
            viewModel.stopMonitoring()
        } else {
            showEnsembleCountdown = true  // TunerMainScreen から @Binding で受け取る
        }
    case .recording:
        viewModel.isRunning ? viewModel.stopRecording() : viewModel.startRecording()
    }
}
```

```swift
private func accentColor(for mode: TunerMode) -> Color {
    switch mode {
    case .soloMonitoring:     return .cyan
    case .ensembleMonitoring: return .green
    case .recording:          return .orange
    }
}
```

`showEnsembleCountdown` は `@Binding var showEnsembleCountdown: Bool` として `TunerMainScreen` から受け取る。

#### ModeSwitcher を3モード対応に更新

| モード | アイコン | カラー |
|---|---|---|
| soloMonitoring | `mic.circle.fill` | `Color.cyan` |
| ensembleMonitoring | `person.2.circle.fill` | `Color.green` |
| recording | `record.circle` | `Color.orange` |

#### PreviewUseCase に `spectrumPublisher` を追加

セクション2参照。

---

### 11. RecordButton.swift を修正

`isRecordingMode: Bool` を `accentColor: Color` に変更する。

```swift
struct RecordButton: View {
    let isRunning: Bool
    let accentColor: Color   // isRecordingMode: Bool から変更
    let action: () -> Void
    ...
}
```

アイコン・ラベルは `accentColor == .orange`（録音モード）で判定する：

```swift
private var startIcon: String {
    accentColor == .orange ? "record.circle" : "mic.circle.fill"
}

private var startLabel: String {
    accentColor == .orange ? "録音開始" : "計測開始"
}

private var stopLabel: String {
    accentColor == .orange ? "録音停止" : "計測停止"
}
```

Preview も `isRecordingMode:` → `accentColor:` に更新する。

---

## 注意事項
- 既存のソロモニタリングのチューニング判定（`updateInTuneState`、`showTuningCelebration`）は一切変更しない
- `EnsembleTuningDetector` は `tunerMode == .ensembleMonitoring` のときのみ起動する（フラグは追加しない）
- チューニング成功判定の閾値（セント範囲・継続時間）は `TunerSettings` の値を使用する。`EnsembleTuningDetector.start()` に `TunerSettings` を渡す
- `spectrumPublisher` の中継はセクション2に記載（`MicrophoneDataSource` → `PitchRepository` → `MonitorPitchUseCase` → `TunerViewModel`）
- Combineを使い、既存のアーキテクチャ（PassthroughSubject / AnyPublisher）に合わせる
- スレッドセーフに注意（`subject.send` はメインスレッドで呼ぶ）
- `TunerViewModel` は `@MainActor` なので、プロパティ更新はそのまま行う

---

## 実装後の確認ポイント

| 確認項目 | 内容 |
|---|---|
| ソロモニタリングの動作が壊れていないか | `showTuningCelebration` が従来通り動くか |
| `tunerMode` の切替UI | ModeSwitcher で `viewModel.tunerMode` を更新しているか |
| `ensembleSpectralWidthThreshold` の値 | 実機テストで5.0を基準に調整（チューニング設定から変更可能） |
| `ensembleStabilityScoreThreshold` の値 | 実機テストで10.0を基準に調整（チューニング設定から変更可能） |
| `TuningCelebrationView` の呼び出し箇所 | 既存の1箇所のまま（追加不要） |
