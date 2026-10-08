# ぞめきチューナー iOS UI 操作レシピ

`SKILL.md` の Maestro MCP 操作基準を前提に、ぞめきチューナー（shinobuetuner）固有のビルド手順・状態のリセット方法・画面遷移・機能別の動作確認手順をまとめる。

新しい機能を追加したり既存機能を改修したりした場合は、実際に本レシピの手順で動作確認したうえで、変更点をこのファイルに反映すること。機能の正式な仕様は `docs/specification.md` を参照する。

## デバイス確定・起動手順

`SKILL.md`「デバイス選択」の手順（起動中デバイスを先に確認する）に従う。このプロジェクトでの推奨デフォルトは **`iPhone 17`**。

```bash
xcrun simctl list devices booted                # 手順1: 起動中の iOS シミュレータを確認
# 0台なら以下で推奨デフォルトを起動、1台ならそれを使う、複数ならユーザーに確認する
xcrun simctl boot "iPhone 17"                   # 手順4: 対象デバイスを確定してから起動（起動済みならエラーは無視してよい）

# 対象デバイスを確定・起動した後で Simulator.app を開く（順序を守る。詳細は SKILL.md 参照）
open -a Simulator
osascript -e 'tell application "Simulator" to activate' \
  -e 'tell application "System Events" to tell process "Simulator" to perform action "AXRaise" of (first window whose name contains "iPhone 17")'

xcrun simctl list devices booted                # 起動中デバイスの UDID を確認
```

⚠️ **Simulator.app が見つからない場合**: この Mac（Xcode 27.0）では `/Applications/Xcode.app/Contents/Developer/Applications/` が存在せず、`open -a Simulator` が「Unable to find application」で失敗する（2026-10-09 確認）。`xcrun simctl` と Maestro は GUI ウィンドウなしでも問題なく動くため、**そのまま続行してよい**。ただしユーザーは操作の様子を目で追えないので、その旨を報告に含めること。（`/Applications/Play.app` 内の `PlaySimulator.app` はサードパーティ製の別アプリなので代わりに使わない）

`device_id`（UDID）が決まったら、以降の `inspect_screen` / `take_screenshot` / `run`（MCP）や `maestro --device <UDID> ...`（CLI）はすべてこの ID を使う。以下のコマンド例の `"iPhone 17"` も、実際に確定したデバイス名または UDID に置き換えること。

## ビルド・起動手順

```bash
cd /Users/ryouta/Dev/iOS/shinobue-tuner-ios
xcodebuild -project shinobuetuner.xcodeproj -scheme shinobuetuner -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' build \
  2>&1 | tee /tmp/ios_build.log | grep -E "error:|BUILD (SUCCEEDED|FAILED)" || true
# ↑ xcodebuild の生ログは非常に冗長なのでコンテキストに直接読み込まない。
#   ログファイルに保存しつつ要点だけ grep で見る。BUILD SUCCEEDED が出なければ /tmp/ios_build.log を確認する

# ビルド成果物のパスは DerivedData 配下。毎回変わるので都度 find で確認する。
# "shinobuetuner-*" は複数の DerivedData ディレクトリにマッチしうるため "shinobuetuner.app" まで指定し、最新の1件に絞る
APP_PATH=$(ls -dt ~/Library/Developer/Xcode/DerivedData/shinobuetuner-*/Build/Products/Debug-iphonesimulator/shinobuetuner.app | head -1)
xcrun simctl install "iPhone 17" "$APP_PATH"

# 日本語ロケールで起動する（シミュレータの言語設定に依存せず、文言を本レシピ・test-case.md と一致させるため）
xcrun simctl launch --terminate-running-process "iPhone 17" dev.seabat.ios.shinobuetuner \
  -AppleLanguages "(ja)" -AppleLocale ja_JP
```

- バンドルID（appId）: `dev.seabat.ios.shinobuetuner`
- アプリは日本語・英語にローカライズされている（`Localizable.xcstrings`）。本レシピの文言はすべて日本語ロケールのもの。英語表示を確認したい場合は `-AppleLanguages "(en)" -AppleLocale en_US` で起動する
- Maestro フローで起動し直す場合も同じ引数を渡す：
  ```yaml
  appId: dev.seabat.ios.shinobuetuner
  ---
  - launchApp:
      stopApp: true
      arguments:
        AppleLanguages: "(ja)"
        AppleLocale: ja_JP
  ```
- 既存のアプリデータ（UserDefaults・Documents の録音ファイル）は `simctl install` では消えない

## 状態のリセット・テストデータの準備

### マイク権限

```bash
xcrun simctl privacy "iPhone 17" grant microphone dev.seabat.ios.shinobuetuner    # 許可済みにする
xcrun simctl privacy "iPhone 17" revoke microphone dev.seabat.ios.shinobuetuner   # 拒否状態にする
xcrun simctl privacy "iPhone 17" reset microphone dev.seabat.ios.shinobuetuner    # 未決定に戻す（次回起動で OS ダイアログが出る）
```

- 権限変更後はアプリを再起動（`launch --terminate-running-process`）しないと反映されない
- OS の許可ダイアログ（「"ぞめきチューナー"がマイクへのアクセスを求めています」等）は Springboard 側の要素だが、`inspect_screen` で拾えれば `tapOn: "許可"` で押せる。拾えない・不安定な場合は事前に `grant` しておく方が確実

### 初回起動時の調子選択（オンボーディング）を出し直す

完了記録 `hasSelectedTuning` は `OnboardingRepository`（UserDefaults）に保存されるため、**アプリをアンインストールして再インストール**するのが最も確実。

```bash
xcrun simctl uninstall "iPhone 17" dev.seabat.ios.shinobuetuner
xcrun simctl install "iPhone 17" "$APP_PATH"
# 必要に応じてここで privacy grant してから launch する
```

⚠️ アンインストールすると Documents の録音ファイルと全設定も消える。プレイリスト系のテストより前に実施するか、後でテストデータを入れ直すこと。

### プレイリスト用のテストデータ

プレイリストはアプリの **Documents** 内の音声ファイルを一覧する。録音操作を経ずにデータを用意したい場合は、データコンテナへ直接コピーする。

```bash
DATA_DIR=$(xcrun simctl get_app_container "iPhone 17" dev.seabat.ios.shinobuetuner data)
ls "$DATA_DIR/Documents"
# 例: macOS の say コマンドで数秒の m4a を生成してコピー
say -o /tmp/test_tone.m4a --file-format=m4af --data-format=aac "テスト"
cp /tmp/test_tone.m4a "$DATA_DIR/Documents/2026-01-01_00-00-00.m4a"

# 頭出し用: 先頭に2秒の無音を入れる（[[slnc ミリ秒]] で無音を挿入できる）
say -o /tmp/test_B.m4a --file-format=m4af --data-format=aac "[[slnc 2000]] テスト"
# 再生確認用: 30秒以上の音声（-r で読み上げ速度を下げ、途中に無音を挟んで長くする。この例で約45秒）
say -r 120 -o /tmp/test_A.m4a --file-format=m4af --data-format=aac \
  "テスト音声です [[slnc 3000]] テスト音声です [[slnc 3000]] テスト音声です [[slnc 3000]] テスト音声です [[slnc 3000]] テスト音声です [[slnc 3000]] テスト音声です [[slnc 3000]] テスト音声です [[slnc 3000]] テスト音声です [[slnc 3000]] テスト音声です [[slnc 3000]] テスト音声です"
```

- 再生の確認（行タップ → 他の行がロックされる、等）には **30秒以上**のファイルを使う。数秒のファイルでは確認中に再生が終わってしまう

- コピー後はプレイリストタブを開き直す（タブ切替 or アプリ再起動）と一覧に反映される
- テスト用ファイルは後片付けとして `rm "$DATA_DIR/Documents/<ファイル名>"` で削除してよい

## 画面遷移マップ

タブバー（3タブ）: `チューナー` / `プレイリスト` / `周波数表`。設定はすべて**フルスクリーンモーダル**（右上「閉じる」で閉じる。スワイプでは閉じない）。

```
起動
├─ スプラッシュ（約1秒）
├─ マイク許可の問い合わせ（未決定時のみ OS ダイアログ）
└─ 調子選択が未完了なら 初回調子選択 (TuningSelectionFullScreenModal) を全画面表示（タブバーも隠れる）
    └─ 調子ドラムロール → 「決定」でのみ閉じる

チューナー
├─ マイク未許可 → PermissionRequestView（「マイクの使用を許可」ボタン）
└─ マイク許可済 → TunerMainScreen
    ├─ 左上: 調子表示（例「6本調子」）→ チューニング設定 (TunerSettingsFullScreenModal)
    ├─ 右上: 歯車 → チューニング設定 (TunerSettingsFullScreenModal)
    │   ※ 計測中・録音中は左上・右上とも無効
    ├─ 中央下部: 使い方ヘルプ（3ページ TabView、横スワイプ）または ピッチグラフ
    └─ 下部コントロールバー
        ├─ 開始/停止ボタン（「計測開始」/「計測停止」、録音モードは「録音開始」/「録音停止」）
        └─ モード切替ボタン（「計測(単)」/「計測(複)」/「録音」）→ popover のホイール Picker
            └─ 計測(複) で開始 → カウントダウン (EnsembleCountdownFullScreenModal: 3 → 2 → 1 → はい！) → 計測開始

プレイリスト (PlaybackListScreen)
├─ 右上: 歯車 → 音声ファイル設定 (PlaybackSettingsFullScreenModal: 並び替え・頭出しのしきい値)
├─ 空状態: 「音声ファイルがありません」「チューナー画面で録音してください」
├─ 行タップ → 再生開始、下部に再生コントロール（シークバー・再生/一時停止・×で停止）
└─ 行を左スワイプ（再生中は不可）→ 「削除」「名前変更」「共有」「頭出し」

周波数表 (FrequencyTableScreen) … タイトル「<N>本調子 周波数表」
└─ 右上: 歯車 → 周波数表の設定 (FrequencyTableSettingsFullScreenModal: 調子・階名のみ)
```

設定の保存先: チューニング設定と周波数表設定の「調子」「階名」は共通（`TunerSettings`）。どちらで変えても両画面に反映される（各画面の `onAppear` / モーダルの `onDismiss` で読み直す）。

## このアプリ特有の注意点

1. **シミュレータのマイク入力は Mac の入力デバイスを拾う**。周囲の音や Mac の入力設定次第で検出ピッチが不安定・あるいは常に無音になるため、**音程判定・セントメーター・祝福エフェクト（「いいね！」）の発火は UI 操作テストの検証対象にしない**。検証するのは、ボタンラベル・モード・画面遷移・無音時表示（`---` / 「音を鳴らしてください」）など、入力に依存しない部分に限る。音程判定はユニットテスト（`shinobuetunerTests`）の担当
2. **計測・録音中は設定系が無効**。左上の調子表示・右上の歯車・モード切替は `disabled` になる。設定を開く前に必ず停止する
3. **30 秒無音で自動停止しアラートが出る**。計測を開始したまま放置すると、次の `inspect_screen` でアラート（「OK」ボタン）が出ていることがある。想定外のアラートが出ていたら閉じてから続行する
4. **モード切替は popover のホイール Picker**。モード切替ボタンをタップ → ホイールの目的の項目をタップすると自動で popover が閉じる。**ホイールの項目は `inspect_screen` に出てこない**ため、座標でタップする。iPhone 17 での実測値（2026-10-09）:
   - 「計測(単)」選択中: 「計測(複)」= `199,771`、「録音」= `199,796`
   - 「計測(複)」選択中: 「計測(単)」= `199,710`
   - 機種やレイアウトが変わると座標もずれるので、外れたら `take_screenshot` で位置を確認する
5. **調子のドラムロール（ホイール Picker）は 1〜13 本調子**。対応済みは六本調子・八本調子のみで、未対応を選ぶとアラート「この調子は近日対応予定です。」→「OK」で直前の調子に戻る
   - 項目の `txt` は **「6本調子」「8本調子」のようなアラビア数字表記**（「六本調子」ではない）
   - 目的の行の座標を直接タップすれば、途中の未対応の調子（七本調子）を経由してもアラートは出ず、目的の調子が選ばれる。iPhone 17 での実測値（2026-10-09）:
     - 初回調子選択モーダル（6本調子が中央）: 「8本調子」= `201,553`、「7本調子」= `201,527`
     - チューニング設定（6本調子が中央）: 「8本調子」= `201,335`／（8本調子が中央）: 「6本調子」= `201,223`
6. **タブバーとモーダル**: フルスクリーンモーダル表示中はタブバーが隠れる。`tapOn: "周波数表"` 等が失敗したら、まずモーダルが開いたままになっていないか確認する
7. **ナビゲーションタイトルと本文で同じ文言が重複することがある**（例：「プレイリスト」はタブ名とヘッダー、「頭出し」はスワイプボタンと設定セクション名、「階名」はセクション名と周波数表の列見出し）。`tapOn: "text"` が意図しない要素に当たる場合は `inspect_screen` で `b`（bounds）を確認し、`index:` か `point:` で区別する
8. **実際のアクセシビリティラベル**（`inspect_screen` で確認した値。2026-10-09 時点）:
   - 各画面右上の歯車: `gearshape`
   - チューニング設定の「ピッチグラフを表示」トグル: テキストでは押しにくいので座標（iPhone 17 で `340,637`）でタップし、状態は `checked` で判定する
   - 階名の Picker 行: 「階名、移動ド」／「階名、固定ド」
   - プレイリスト設定の並び替え行: 「並び替え、作成日時（新しい順）」のように「項目名、現在値」の形
   - 再生コントロール: × は「閉じる」、再生/一時停止ボタンは「一時停止」（再生中）／「再生」（停止・再生終了後）
   - 再生中の行のアイコン: `waveform`
9. **周波数表のスクロール位置はタブを切り替えても残る**。先頭行（4'）や特定の行を確認する前に、`scrollUntilVisible`（`direction: UP`）で先頭まで戻してから確認する
10. **再生が終わっても再生コントロールは消えない**（「再生」ボタンの状態で残る）。次の操作の前に「閉じる」（×）で閉じる
11. **一定秒数の待機**: `extendedWaitUntil: { notVisible: ... }` は対象が最初から見えていないと即座に完了し、待機にならない。録音中に数秒待ちたい場合は、Bash の `sleep` を挟むか、MCP の `run` を分けて呼ぶ

## Maestro 特有の操作クセ（他プロジェクトの iOS 版で判明した汎用的な注意点）

1. **ソフトウェアキーボードの閉じ方**（名前変更アラートの TextField 等で入力した後）：
   - `hideKeyboard` は失敗することがあるので頼らない
   - `tapOn: "完了"` は IME の予測変換候補チップに誤って当たることがあるため信頼しない
   - **最も確実な方法**：`inspect_screen` で `resource-id=Done` を持つ要素を探し、その `bounds` の中心座標を `point:` で直接タップする
   - 日本語入力後は、キーボードを閉じた直後に対象フィールドの `val`/`text` を `inspect_screen` で再確認し、余分な文字が混入していないか確かめる
   - なお名前変更はアラート内の TextField なので、キーボードを閉じずにそのままアラートの「変更」ボタンを押せる（2026-10-09 確認）
   - 名前変更の TextField は**中央をタップしてから `eraseText` するとカーソルが途中に入り、消し残りが出る**（例: `regression_test52-37`）。**TextField の右端をタップ**してから `eraseText: 60` → `inputText` の順で入力する
2. **長押し（`longPressOn`）やタップはテキストの前後に見えない空白が含まれると失敗する**ことがある。`Element not found` になったら `point:` にフォールバックする
3. **`maestro test <flow.yaml>` の `takeScreenshot` は出力先が Maestro のテスト実行フォルダ配下に制限される**。単純に目視・証跡保存したいだけなら `xcrun simctl io "<device>" screenshot <path>` を使う
4. **macOS の BSD `sort -u` は日本語（マルチバイト文字）で重複排除に失敗することがある**。`maestro hierarchy --compact` の出力から一覧を作る際は `awk '!seen[$0]++'` を使う
5. **Maestro MCP と Maestro CLI を同じセッションで併用しない**。MCP を使っている最中に CLI（`maestro --device <id> hierarchy` 等）を1回実行しただけで iOS ドライバが外れ、以後 MCP が「Device became unreachable during deviceInfo」で使えなくなり復帰しなかった（2026-10-09 発生）。
   - 基本は MCP だけで操作する。CLI は MCP がまったく疎通しないときのフォールバックとし、**一度 CLI に切り替えたら最後まで CLI で通す**（`maestro --device <UDID> test flow.yaml` と `maestro --device <UDID> hierarchy`。1回あたり約20秒かかる）
   - `list_devices` で同じ UDID が simulator と real の2件に重複して表示されることがある。シミュレータを使うときは simulator 側を選ぶ

## 機能別確認レシピ

### 起動フロー（初回の調子選択・マイク許可）

1. 「状態のリセット」の手順でアンインストール → 再インストール。マイクは `grant` しておく（OS ダイアログ操作を省くため）
2. 起動 → スプラッシュ後に「お使いの篠笛の調子を選んでください」の全画面モーダルが出る
3. ドラムロールで調子を選択（初期値は六本調子）→ 「決定」
4. モーダルが閉じ、チューナー画面左上の調子表示が選んだ調子（例「8本調子」）になっていることを確認
5. アプリを再起動しても調子選択モーダルが再表示されないことを確認
- マイク未許可パターン: `revoke` して再起動 → チューナータブに「マイクのアクセスが必要です」「マイクの使用を許可」が出る

### チューナー（計測・録音）

1. **計測(単)**: モードが「計測(単)」の状態で「計測開始」→ ラベルが「計測停止」に変わる。無音なら音符表示は `---` / 「音を鳴らしてください」。「計測停止」で元に戻る
2. **計測(複)**: モード切替で「計測(複)」→「計測開始」→ カウントダウンモーダル（3 → 2 → 1 → はい！）→ 自動で閉じて計測中になる。計測中はモード切替が無効
3. **録音**: モード切替で「録音」→「録音開始」→ 数秒待つ →「録音停止」→ プレイリストタブに `yyyy-MM-dd_HH-mm-ss.m4a` 形式の行が追加される
4. **ヘルプ / ピッチグラフ**: タブ表示直後（計測未開始）は「使い方」ヘルプ（3ページ、横スワイプで切替）。ピッチグラフ設定 On なら計測開始後に「ピッチグラフ（5秒間）」に切り替わる。Off ならヘルプのまま

### チューニング設定

- 開き方: 停止中に右上の歯車、または左上の調子表示
- 項目順: 調子（ホイール）→ 階名（移動ド／固定ド）→ 表示設定（「ピッチグラフを表示」トグル）→ セント範囲 → 継続時間 → アンサンブル 調整オプション（非推奨）→「デフォルトに戻す」
- フォームは縦に長いので、下の項目は `scroll` してから `inspect_screen` する
- 「デフォルトに戻す」で調子は六本調子・ピッチグラフ On・移動ド・±10 セント・1.0 秒等に戻る。**初回の調子選択完了記録は消えない**（`.claude/rules/notes.md` 参照）ので、再起動しても調子選択モーダルは出ないのが正しい

### プレイリスト

1. **空状態**: ファイルが無いと「音声ファイルがありません」
2. **再生**: 行をタップ → 下部に再生コントロール。他の行は半透明になりタップ不可。× で停止・選択解除
3. **名前変更**: 行を左スワイプ →「名前変更」→ アラート「名前を変更」の TextField を編集（拡張子は自動付加）→「変更」
4. **頭出し**: 行を左スワイプ →「頭出し」→ `[頭出し]` 付きの m4a が新たに追加される（無音のみのファイルでは失敗・エラーアラートになる場合がある）
5. **削除**: 行を左スワイプ →「削除」→ アラート「削除の確認」→「削除」
6. **並び替え**: 右上歯車 → 「並び替え」で「作成日時（新しい順）」「作成日時（古い順）」「ファイル名（Z → A）」「ファイル名（A → Z）」→「閉じる」で一覧の順序が変わる
- スワイプ: `swipe: { from: { text: "<ファイル名>" }, direction: LEFT }` を基本とし、外れる場合は行の bounds を見て `start`/`end` 座標で指定する

### 周波数表

- タイトルは「<N>本調子 周波数表」。表の上に「階名：移動ド（ド＝<主音名>）」（六本調子は「ド＝B♭」、八本調子は「ド＝C」）または「階名：固定ド（ド＝C）」を表示
- 先頭行・末尾行を確認するときは、前回のスクロール位置が残っているので先に先頭まで戻す（注意点 9）
- 列: 運指・階名・音名・Hz。高い音（4'）から筒音まで。六本調子は E♭7 ≈ 2500 Hz 〜 G4 ≈ 394 Hz、八本調子は F7 ≈ 2807 Hz 〜 A4 = 442.000 Hz
- 1' と 一（メリ）の行がシアン系でハイライトされる（色の確認は `take_screenshot`）
- 右上歯車 →「周波数表の設定」で調子・階名を変更（フッター「この設定はチューナーと共通です。」）
