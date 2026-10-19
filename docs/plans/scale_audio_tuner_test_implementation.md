# 音階音源による TunerMainScreen テスト 実装計画

## ステータス：実装済み（2026-10-19）

---

## 概要

六本調子・八本調子の音階（移動ドの ド レ ミ ファ ソ ラ シ ド）を1音1秒ずつ鳴らす .m4a を用意し、それを入力にして TunerMainScreen が正しく動くかをテストできる仕組みを作る。

- 六本調子：ド(B♭5) レ(C6) ミ(D6) ファ(E♭6) ソ(F6) ラ(G6) シ(A6) ド(B♭6)
- 八本調子：ド(C6) レ(D6) ミ(E6) ファ(F6) ソ(G6) ラ(A6) シ(B6) ド(C7)
- 先に六本調子で仕組みを作って確認し、問題がなければ八本調子に広げる

---

## 方針

### 音源をマイクの代わりに入力する

シミュレータのマイクは Mac の入力デバイスをそのまま使うので、.m4a を「マイク入力」として流し込む標準の方法はない。この Mac には BlackHole などの仮想オーディオデバイスもない。スピーカーで鳴らしてマイクで拾う方法は、周囲の音の影響を受けて再現性がない。

そこで **Debug ビルドに限り、起動引数でマイクの代わりに音声ファイルを入力にする**。入れ替えるのは入力の入口だけで、FFT/HPS によるピッチ検出 → ViewModel → TunerMainScreen の経路は本番と同じものを通す。

### 2段構えで検証する

| 検証 | 手段 | 確認すること |
|---|---|---|
| A. ピッチ検出 | 単体テスト（Swift Testing） | 8音の順番・運指名・階名・音名・セント誤差（±5 セント以内） |
| B. 画面表示 | Maestro（E2E） | 8音それぞれで「運指名 → 階名 → 音名」が画面に並んで表示されること |

1音1秒だと、Maestro の画面チェックが間に合わず音を取りこぼすことがある。そのため音源はループ再生にし、Maestro では「各音が表示されること」だけを確認する。順番と精度の厳密な確認は単体テストで行う。

---

## 実装内容

### 追加・修正ファイル

| 操作 | ファイル |
|---|---|
| 新規作成 | `docs/test/scripts/generate_scale_m4a.sh` |
| 新規作成 | `shinobuetunerTests/Resources/rokuhon_scale.m4a` |
| 新規作成 | `shinobuetunerTests/Resources/hachihon_scale.m4a` |
| 新規作成 | `shinobuetuner/Data/DataSource/PitchDataSource.swift` |
| 新規作成 | `shinobuetuner/Data/DataSource/AudioFileDataSource.swift` |
| 修正 | `shinobuetuner/Data/DataSource/MicrophoneDataSource.swift` |
| 修正 | `shinobuetuner/Data/Repository/PitchRepositoryImpl.swift` |
| 新規作成 | `shinobuetunerTests/ScaleAudioPitchDetectionTests.swift` |
| 新規作成 | `docs/test/maestro/tuner_scale_rokuhon.yaml` |
| 新規作成 | `docs/test/maestro/tuner_scale_hachihon.yaml` |
| 修正 | `.claude/skills/ios-ui-operator/recipe.md`（実行手順） |
| 修正 | `.claude/rules/notes.md`（設計メモ） |
| 修正 | `.gitignore`（Maestro のスクリーンショット） |

### 1. テスト用音源（`docs/test/scripts/generate_scale_m4a.sh`）

- 使い方：`docs/test/scripts/generate_scale_m4a.sh <6|8> [出力先]`
- ffmpeg の `aevalsrc` で 48 kHz・モノラル・8秒の AAC（.m4a）を作る
- 周波数は A4 = 442 Hz の12平均律で計算する。八本調子は六本調子の MIDI 番号を +2 半音ずらす（運指は調子によらず共通という既存の方針に合わせる）
- 基音に第2・第3倍音を足す（振幅 0.5 / 0.25 / 0.15）。HPS は倍音の積で基音を探すため、純音だと検出が不安定になる
- 音の切り替わりでクリックノイズが出ないよう、各音の頭と終わりに 20 ms のフェードを入れる
- 出力先は `shinobuetunerTests/Resources/`。テストバンドルにだけ入り、アプリ本体には入らない（`shinobuetuner/` 配下に置くと同梱されてしまう）

| 調子 | ド | レ | ミ | ファ | ソ | ラ | シ | ド |
|---|---|---|---|---|---|---|---|---|
| 六本 | B♭5 936.565 | C6 1051.259 | D6 1179.998 | E♭6 1250.165 | F6 1403.263 | G6 1575.109 | A6 1768.000 | B♭6 1873.131 |
| 八本 | C6 1051.259 | D6 1179.998 | E6 1324.503 | F6 1403.263 | G6 1575.109 | A6 1768.000 | B6 1984.513 | C7 2102.518 |

（単位は Hz）

### 2. 入力元の差し替え（Data 層）

- `PitchDataSource` プロトコルを追加し、`MicrophoneDataSource` を準拠させる
- `AudioFileDataSource`（`#if DEBUG`）を追加する
  - `AVAudioPlayerNode` で音源をループ再生（`scheduleBuffer(_:at:options: .loops)`）する
  - playerNode の出力にタップを付け、本番と同じ `MicrophoneDataSource.detectPitchWithSpectrum` でピッチを検出する
  - `mainMixerNode.outputVolume = 0` にして、スピーカーからは鳴らさない（タップは playerNode から取るので検出には影響しない）
  - マイク権限の確認はそのまま行う（テスト前に simctl で許可しておく）
- `PitchRepositoryImpl` は `any PitchDataSource` を受け取るようにし、既定の入力元を次の順で決める
  - Debug ビルドで起動引数 `-UITestAudioFile <ファイル名>` がある → `AudioFileDataSource`
  - それ以外 → `MicrophoneDataSource`
- 音源ファイルは、アプリのデータ領域の `Library/UITestAudio/` に置く。Documents に置くとプレイリストに表示されてしまうため
- 切り替えの分岐は、当初は `TunerViewModel` に置く予定だった。Presentation 層が DataSource を知らずに済むよう、Data 層の `PitchRepositoryImpl` に置くことにした

### 3. 単体テスト（`ScaleAudioPitchDetectionTests`）

- 音源をデコードし、本番のタップと同じく 4096 フレームずつ区切って `detectPitch` に通す
- 1秒ごとの区間について、切り替わり付近（前後 0.15 秒）を除いた区間を判定する。確認するのは次の4つ
  - 音名（`westernName`）
  - 運指名（`fingeringName`）
  - 階名（移動ド）
  - セント誤差が ±5 セント以内であること
- 六本調子と八本調子をパラメータ化したテストにする
- 運指名・階名はローカライズ文字列なので、日本語ロケールで実行する：`xcodebuild test ... -testLanguage ja -testRegion JP`

### 4. Maestro フロー（`docs/test/maestro/tuner_scale_{rokuhon,hachihon}.yaml`）

- 起動引数を付けてアプリを起動する
  - `UITestAudioFile`：入力にする音源のファイル名
  - `selectedTuning`、`solfegeSystem`、`hasSelectedTuning`：設定を UserDefaults の引数ドメインで上書きする。調子・移動ドを指定し、初回の調子選択画面を飛ばすため、事前に設定画面を操作する必要がない
- 左上の調子表示を確かめてから「計測開始」を押す
- 各音について、`extendedWaitUntil` で `text: <階名>` / `rightOf: <運指名>` / `leftOf: <音名>` が表示されるまで待つ（timeout は 20 秒）
  - 3つの条件を1回の問い合わせで確かめるので、確認の途中で音が切り替わっても組み合わせを取り違えない
  - わざと誤った組み合わせ（運指「１」の右に「レ」）を指定すると失敗することも確かめた
- 音ごとに `takeScreenshot` を撮り、最後に「計測停止」を押す

---

## 途中で見つかった問題：セント精度（修正済み）

### 症状

単体テストで、C6・D6・E♭6・G6 のセント誤差が 5.2〜5.6 セントになり、±5 セントを超えた。検出した周波数は 1054.6874 Hz（= 11.71875 Hz × 90）のように、ビンの中心ちょうどの値だった。

### 原因

放物線補間を HPS スペクトルの上で行っていた。HPS は3つのスペクトルの積なのでピークが極端に鋭く、隣のビンはピークの約1万分の1しかない（例：ピーク `9.8e16` に対して隣は `3.0e12`）。そのため補間で求まるずれがほぼ 0 になり、**検出周波数がビンの中心（約 11.7 Hz 刻み）に丸められていた**。B♭5 付近では 1 ビンが約 21 セントにあたるので、正しい音程の笛でも最大で約 ±10 セントずれて表示されることがあった。

### 補間方法の比較

G5〜D7 の20音 × 位相7通りについて、テスト音源と同じ倍音構成の信号で比べた。

| 補間方法 | 最大誤差 |
|---|---|
| 修正前：HPS の上で放物線補間 | 9.82 セント |
| 元のスペクトル（パワー）で放物線補間 | 2.37 セント |
| 元のスペクトル（振幅）で放物線補間 | 1.15 セント |
| **元のスペクトル（パワーの対数）で放物線補間** | **0.36 セント** |

### 修正内容（`MicrophoneDataSource.swift`）

- 鳴っている音のビンは、今までどおり HPS で決める（オクターブの取り違えを防ぐ役割はそのまま）
- 周波数の細かい補正（`refinedPeakBin`）だけを元のパワースペクトルで行う
  - HPS で選んだビンの前後1ビンの中から、元スペクトルの極大を探す
  - そのビンと両隣の3点について、パワーの対数で放物線補間する
  - 両隣のどちらかの値が 0 以下で対数がとれないときは補正しない
- 同じ処理が2つ書かれていた `detectPitch` は、`detectPitchWithSpectrum(...).pitch` を呼ぶだけにした
- 計測(複) の判定に渡す HPS スペクトル（戻り値の `magnitudes`）は変えていない

---

## 実行手順

詳しくは `.claude/skills/ios-ui-operator/recipe.md` の「音声ファイルによるチューナー確認」を参照する。

```bash
# 1. Debug ビルドをインストールし、マイク権限を許可する
xcrun simctl install "iPhone 17" "$APP_PATH"
xcrun simctl privacy "iPhone 17" grant microphone dev.seabat.ios.shinobuetuner

# 2. 音源をアプリのデータ領域にコピーする
DATA_DIR=$(xcrun simctl get_app_container "iPhone 17" dev.seabat.ios.shinobuetuner data)
mkdir -p "$DATA_DIR/Library/UITestAudio"
cp shinobuetunerTests/Resources/*_scale.m4a "$DATA_DIR/Library/UITestAudio/"

# 3. Maestro フローを実行する
maestro --device <UDID> test docs/test/maestro/tuner_scale_rokuhon.yaml docs/test/maestro/tuner_scale_hachihon.yaml

# 単体テスト（日本語ロケールで実行する）
xcodebuild test -project shinobuetuner.xcodeproj -scheme shinobuetuner \
  -destination 'platform=iOS Simulator,name=iPhone 17' -testLanguage ja -testRegion JP \
  -only-testing:shinobuetunerTests
```

---

## 結果（2026-10-19、iPhone 17 / iOS 26.0 シミュレータ）

| 確認 | 結果 |
|---|---|
| 単体テスト（既存分を含む全件） | 成功。音階テストは六本・八本とも全区間で ±5 セント以内 |
| Maestro 六本調子 | 成功（26秒） |
| Maestro 八本調子 | 成功（26秒） |
| Release ビルド | 成功（補間の修正より前に確認） |

画面上の例として、八本調子の C7（2102.518 Hz）は修正後に「2102.6 Hz・+0.1 セント」と表示された。

---

## 注意点

- 起動引数で渡した設定は、保存されている設定より優先される。このテストで起動している間は、設定画面で調子を変えても反映されない。普段どおり確認したいときは、引数なしで起動し直す
- `xcodebuild test` で単体テストを流した直後は、シミュレータが一度止まっているため Maestro MCP がつながらない。単体テストと続けて流すときは Maestro CLI を使う
- `takeScreenshot` の保存先は実行方法で変わる
  - CLI：`~/.maestro/tests/<日時>/<フロー名>/takeScreenshot/`
  - MCP：実行時のカレントディレクトリ（リポジトリ直下。`.gitignore` 済み）
- アプリをアンインストールすると `Library/UITestAudio/` の音源も消える。その後はもう一度コピーする

---

## 今後の課題（未対応）

- ピッチグラフ右側の音名ラベルが「C#7」「F#6」と半角の `#` になっている。上の大きな音名表示（`♯`）と表記が揃っていない。今回の変更とは関係しない既存の挙動
