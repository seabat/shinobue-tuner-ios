---
name: ios-ui-operator
description: ぞめきチューナー（shinobuetuner）の iOS アプリをシミュレータ / 実機で操作し、動作確認や実装後の結合テストを行う。Maestro MCP（`maestro mcp`）経由で UI 階層取得・タップ・テキスト入力・スワイプを実行する。
---

# ぞめきチューナー固有の情報

ビルド・起動手順、状態のリセット方法、画面遷移マップ、機能別の動作確認レシピは `recipe.md` を参照してください。
新しい機能を追加したり既存機能を改修した場合は、確認後に `recipe.md` を更新してください。

以下は Maestro MCP の汎用的な操作基準です（このアプリ固有ではありません）。

# 前提

- Maestro CLI がインストールされていること（`brew install maestro` 等。`maestro --version` で確認）
- Maestro MCP サーバーがこの Mac に登録されていること：
  `claude mcp add -s user maestro -- maestro mcp`
- `mcp__maestro__*` ツールが deferred（未ロード）の場合は、使う前に必ず `ToolSearch` で読み込む：
  `ToolSearch({query: "select:mcp__maestro__list_devices,mcp__maestro__inspect_screen,mcp__maestro__take_screenshot,mcp__maestro__run,mcp__maestro__cheat_sheet"})`

# ツール

## デバイス選択

どのシミュレータを使うかは、次の手順で**必ず既存の起動状況を確認してから**決める。いきなり `recipe.md` 記載のデバイス名を起動しない（後述の事故を防ぐため）。

1. `xcrun simctl list devices booted`（または `list_devices`）で**現在起動中の iOS シミュレータ**を確認する
2. **起動中の iOS シミュレータが1台だけ** → それを使う。新たに他のデバイスを起動しない
3. **起動中の iOS シミュレータが複数** → どれを操作対象にすべきかユーザーに確認する（ユーザーが実際に見ているウィンドウが分からないため、憶測で選ばない）
4. **起動中の iOS シミュレータが0台** → `recipe.md` に記載の推奨デバイス（`iPhone 17`）を `xcrun simctl boot "<device name>"` で起動する
5. 対象が決まったら `device_id`（UDID）を確定し、以降の `inspect_screen` / `take_screenshot` / `run` はすべてこの `device_id` を渡す

**重要**：`xcrun simctl` や Maestro のコマンドはシミュレータの GUI ウィンドウ（Simulator.app）を開かなくても実行できてしまう（CoreSimulator デーモンに直接指示するため）。**ユーザーが操作の様子を目で追えるように、対象デバイスを確定した後に必ず以下を実行し、Simulator.app のウィンドウを表示・前面化すること。**

```bash
open -a Simulator
# Simulator.app が「最後に使った別のデバイス」をデフォルトで開いてしまうことがあるため、
# 必ず対象デバイスのウィンドウを明示的に前面化する（見た目上どれが対象か分からなくなるのを防ぐ）
osascript -e 'tell application "Simulator" to activate' \
  -e 'tell application "System Events" to tell process "Simulator" to perform action "AXRaise" of (first window whose name contains "<device name>")'
```

Simulator.app 自体が見つからない（`open -a Simulator` が「Unable to find application」になる）環境では、GUI なしのまま続行してよい（simctl・Maestro は動く）。その旨をユーザーへの報告に含める。

⚠️ **既知の事故**: `open -a Simulator` を対象デバイス確定前に実行すると、Simulator.app が独自の「前回使ったデバイス」をデフォルトで起動し、意図したデバイスが落ちてしまうことがある（`iPhone 17` を操作中に `open -a Simulator` を実行したところ `iPhone SE` が代わりに起動され `iPhone 17` が停止した事例あり）。**必ず手順1〜4でデバイスを確定・起動してから `open -a Simulator` を実行する**こと。

## UI 階層取得
`inspect_screen` は、現在の画面の UI 階層をコンパクトな JSON で返す。トップレベルは `ui_schema`（このプラットフォームでの略語定義とデフォルト値）と `elements`（`c` で子要素をネストしたツリー）の2キー。

要素のキーは省略形で表される：
- `b` = bounds
- `txt` = text
- `rid` = resource-id
- `a11y` = accessibilityText / content-desc
- `hint` = hintText
- `cls` = class
- `val` = value
- `scroll` = scrollable

`clickable` / `checked` / `focused` / `selected` / `enabled` などの真偽値フラグは、`ui_schema.defaults` に対して非デフォルトの場合のみ出力される。サイズ0の要素や空のコンテナは除外される。

**重要**：
- 上記の省略キー（`a11y` など）はそのまま Maestro のセレクタキーとして使えない。`tapOn` などのセレクタでは `a11y` の値を `text:` として指定する（`accessibilityText` をそのまま `text:` の値として使う）
- `txt` の値は**必ずこの出力から逐語コピー**すること。スクリーンショットを見て文字起こししない（例：歯車アイコンを見て「設定」ボタンだと決め打ちするのは、実際のラベルと異なる典型的な幻覚パターン。SF Symbols のボタンは `a11y` が英語のシンボル名由来の文字列になっていることがある）
- 画面が変化したら都度 `inspect_screen` を呼び直すこと

**トークン節約**：
- `inspect_screen` の abbreviated JSON は Maestro CLI の `hierarchy` コマンドの生出力より簡潔なので、
  MCP ツールが正常に動作する場合はこちらを優先する
- `mcp__maestro__*` が疎通しない場合のフォールバックとして CLI（`maestro --device <id> hierarchy --compact`）
  を使う。**MCP と CLI を同じセッションで併用すると MCP のドライバが外れて復帰しないことがある**ため、一度 CLI に
  切り替えたら最後まで CLI で通す（詳細は `recipe.md`「Maestro 特有の操作クセ」）。CLI は差分モードが無いため、**特定の要素を探すだけの場合は
  出力を `| grep -i "<キーワード>"` で絞り込んでから読むこと**。フルダンプを毎回そのまま読み込むのは避ける
- 結果確認が不要な連続操作（タップ→入力→キーボードを閉じる、等）は、可能な限り1つの Maestro フロー
  YAML にまとめて1回の `run`（または CLI `maestro test`）呼び出しで実行し、都度の Bash 呼び出しを減らす

## スクリーンショット
`take_screenshot` は現在のデバイス画面の画像を返す。色・ハイライト・グラフ描画など見た目を目視確認したい場合、または `inspect_screen` だけでは要素が特定できない場合の補助手段として使う。

**画像1枚あたりのトークンコストは高いため、`inspect_screen` だけでは判断できない場合に限って使用し、単なる
動作確認の記録目的では多用しないこと**（デグレテスト等で FAIL の証跡として保存する場合を除く）。

## 操作の実行
`run` は Maestro のコマンドを実行する。`yaml`（インライン文字列）・`files`（YAMLファイルのパス配列）・`dir`（フォルダ）のいずれか1つを指定する。

**探索・デバッグ目的では `yaml` によるインライン1コマンドが推奨**：

```json
{ "device_id": "...", "yaml": "- tapOn: \"周波数表\"" }
```

複数ステップをまとめた完全なフローを一度に渡すことも可能。`env` で環境変数を注入できる。構文はこの呼び出し内で検証される。

代表的なコマンド（詳細な構文は `cheat_sheet` を参照）：
- `tapOn: "<text>"` — テキスト（表示文字列 or アクセシビリティラベル）に一致する要素をタップ
- `tapOn: { point: "50%,50%" }` — 座標（絶対値 or 相対%）でタップ。テキストを持たない要素へのフォールバック
- `inputText: "<text>"` — フォーカス中のフィールドにテキスト入力
- `scroll` / `swipe` — スクロール・スワイプ
- `back` — 戻る操作
- `launchApp` — アプリ起動（`appId` はフローの1行目で宣言する）

`text:` セレクタは**完全一致の正規表現（IGNORE_CASE）**であり、部分一致しない。長い文字列の一部だけを渡すと一致しないため、`inspect_screen` で得た文字列全体を使うか、`"〇〇.*"` のような正規表現でアンカーすること。`(` `)` `?` など正規表現の特殊文字を含む文字列（例：「計測(単)」）はエスケープするか `.*` で逃がすこと。

## コマンド構文リファレンス
未知のコマンド・必須引数・ネストしたプロパティ・条件分岐・複数画面のフローを書く前に `cheat_sheet` を呼び出して構文を確認する。

# 操作の進め方

次のループを繰り返す：

```
inspect_screen（今の画面を見る）→ 判断する → run（1手だけ実行する）→ inspect_screen（結果を確認する）→ ...
```

事前に固定の `.yaml` フローファイルを用意する必要はない。`recipe.md` には画面遷移や確認手順を口語で記載してあるので、それをもとに毎回その場で `inspect_screen` の結果から次の1手（`run` に渡す inline YAML）を組み立てること。機種やレイアウトが変わっても、都度その場の階層を見て判断すれば対応できる。

# 操作ルール

1. テキスト入力の前に、対象フィールドが `focused` になっているか `inspect_screen` で確認する
2. `scroll` が可能な要素（`scroll` 属性を持つ要素）配下に目的の要素が見当たらない場合は、スクロールしてから再度 `inspect_screen` する
3. アニメーション（モーダル表示・カウントダウン等）の直後は情報が不足していることがある。数秒待ってから `inspect_screen` をやり直す
4. `text:` セレクタは完全一致・正規表現である点に注意し、`inspect_screen` の `txt`/`a11y` を逐語コピーして使う
