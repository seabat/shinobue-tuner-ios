---
name: regression-test-runner
description: ぞめきチューナーのリグレッションテストを iOS シミュレータ / 実機上で実際に操作して実行する。test-case.md のテストケースを現在のコードと照合して自動で追加・更新した上で、ios-ui-operator を呼び出して検証し、結果を記録する。
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill, Agent
---

# リグレッションテスト実行

`test-case.md`（本スキルと同じディレクトリ）に定義されたテストケースを、シミュレータ/実機を
実際に操作して検証し、結果を記録する。すべての出力は日本語で行う。

このスキルは**手動呼び出し専用**（`disable-model-invocation: true`）。シミュレータ操作を
伴う重い処理のため、他の変更をトリガーに自動起動することはない。

**トークン節約（全ケース実行時）**: 引数なし・複数No.指定などで実行件数が多い場合、UI階層ダンプや
ビルドログで手元の会話コンテキストが肥大化しやすい。テスト実行を `Agent` ツール
（`subagent_type: "general-purpose"`）でバックグラウンド実行する。サブエージェントは会話の文脈を
引き継がないため、本ファイル・`test-case.md`・`../ios-ui-operator/SKILL.md`・`recipe.md` の**絶対パス**、
対象デバイス（名前と UDID）、実行順序（前提条件の依存関係を考慮した順）、Maestro MCP ツールを
`ToolSearch` でロードする必要があることを明示した上で、`test-case.md` 自体は編集させず
結果の要約（結果列にそのまま貼れる書式）のみを返させる。呼び出し元はサブエージェントの結果を受け取ってから
`test-case.md` に反映する。単一ケースの再実行など軽量な場合はこの限りではなく、直接実行してよい。

---

## 引数の解釈

呼び出し時の引数で対象範囲を絞り込める。

- 引数なし → 全ケースが対象
- カンマ区切りの数値（例 `3,5`）→ 対象 No. を限定

対象外のケースは今回スキップとし、結果列は変更しない。

---

## ステップ1: テストケースの棚卸し（自動追加・更新）

1. `test-case.md` を読み込む
2. 現在の画面構成・仕様を確認する
   - 画面一覧: `shinobuetuner/Presentation/View/` 配下の `*Screen.swift`・`*FullScreenModal.swift`・`PermissionRequestView.swift`
   - 機能仕様: `docs/specification.md`
   - 画面遷移・機能別の操作手順: `../ios-ui-operator/recipe.md`
   - 非自明な設計上の落とし穴: `.claude/rules/notes.md`
3. test-case.md に記載済みの No. が対応する機能と突き合わせ、新規画面・新規機能・新規設定項目で
   対応するケースがなければ、既存の表記（No. / 目的 / 前提 / 手順 / 期待 / 結果）に倣って末尾の番号で追加する。
   既存ケースの手順や文言が実装と乖離していれば更新する
   - `.claude/rules/notes.md` に、操作で確認できる落とし穴（例:「デフォルトに戻す」で初回調子選択が
     再表示されない）が新たに追記されていれば、対応する専用ケースがあるか確認し、なければ追加する
   - 音程判定・セント値など、シミュレータのマイク入力に依存する挙動はケースにしない
     （`ios-ui-operator/recipe.md`「このアプリ特有の注意点」1 参照。ユニットテストの担当）
4. 追加・更新した内容があれば `test-case.md` を保存し、内容をステップ6の最終報告に含める。
   変更がなければそのまま次へ進む
   - **ユーザーへの事前確認は不要**。自律的に追加・更新して実行まで進め、事後にまとめて報告する

---

## ステップ2: 実行対象と実行順序の決定

引数の解釈に従い、実行する No. の一覧を確定する。

`test-case.md` の各ケースの「前提」（状態のリセット要否・テストデータ要否）を見て、実行順序を決める。
特に**アンインストールを伴うケース（初回起動系）は録音ファイル・設定を消す**ため、先頭にまとめて実行し、
その後に設定系・プレイリスト系を実行する。

---

## ステップ3: ビルド・起動

実行前に必ずアプリをビルド・インストール・起動する（`ios-ui-operator` の操作ループに入る前に完了させておく）。
手順の詳細は `../ios-ui-operator/recipe.md`「デバイス確定・起動手順」「ビルド・起動手順」に従う。

**トークン節約**: `xcodebuild` は成功時・失敗時ともに大量の冗長なログを出す。
生ログをそのままコンテキストに読み込まず、必ずログファイルに保存した上で要点だけを `grep` で抽出する
（失敗時のみログファイル該当箇所を読みに行く）。

```bash
xcrun simctl list devices booted   # 起動中デバイスを確認。0台なら iPhone 17 を起動、複数ならユーザーに確認
xcrun simctl boot "iPhone 17"      # 対象デバイスを確定してから起動（起動済みならエラーは無視）
open -a Simulator
osascript -e 'tell application "Simulator" to activate' \
  -e 'tell application "System Events" to tell process "Simulator" to perform action "AXRaise" of (first window whose name contains "iPhone 17")'

cd /Users/ryouta/Dev/iOS/shinobue-tuner-ios
xcodebuild -project shinobuetuner.xcodeproj -scheme shinobuetuner -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' build \
  2>&1 | tee /tmp/ios_build.log | grep -E "error:|BUILD (SUCCEEDED|FAILED)" || true
# ↑ BUILD SUCCEEDED が出なければ /tmp/ios_build.log を tail -80 等で確認する

APP_PATH=$(ls -dt ~/Library/Developer/Xcode/DerivedData/shinobuetuner-*/Build/Products/Debug-iphonesimulator/shinobuetuner.app | head -1)
xcrun simctl install "iPhone 17" "$APP_PATH"
xcrun simctl privacy "iPhone 17" grant microphone dev.seabat.ios.shinobuetuner
xcrun simctl launch --terminate-running-process "iPhone 17" dev.seabat.ios.shinobuetuner \
  -AppleLanguages "(ja)" -AppleLocale ja_JP
```

デバイス選択の詳細・複数起動時の確認手順は `../ios-ui-operator/SKILL.md` の「デバイス選択」を参照する。
ケースごとに必要な状態のリセット（アンインストール、マイク権限の revoke 等）は、各ケースの「前提」に従い
`recipe.md`「状態のリセット・テストデータの準備」の手順で行う。

---

## ステップ4: 各ケースの実行

対象の各 No. について、以下を1件ずつ実施する。

1. ケースの「前提」に記載された状態を用意する（リセット・権限・テストデータ）
2. `test-case.md` の「手順」に記載された操作を、Skill ツールで `ios-ui-operator` を呼び出して実行する。
   実際の要素特定・タップ座標・キーボード操作等の作法は、`ios-ui-operator` とその `recipe.md`
   の判断に委ねる（本スキルでは再定義しない）
3. 実行結果を「期待」と照合し、PASS / FAIL を判定する
4. **前提条件となるケース（録音・ファイル追加など）が FAIL した場合**、それに依存する後続ケース
   （再生・名前変更・削除等）は実施せず `SKIP（前提条件未成立: No.X FAIL）` として記録する
5. FAIL したケースのみ、証跡としてスクリーンショットを取得する
   （`take_screenshot` または `xcrun simctl io <device> screenshot <path>`）。本スキルと同じディレクトリの
   `screenshots/` 配下に `ios_<No>_<実行日 YYYYMMDD>.png` として保存する（ディレクトリがなければ作成する）
6. 1件 FAIL・SKIP しても実行を中断せず、対象の全ケースを最後まで実施する
7. 全ケース終了後、テストで作成した録音ファイル等は後片付けしてよい（ユーザーの既存ファイルは消さない）

---

## ステップ5: 結果の記録

各ケースの「結果」列を、直近の実行結果のみで上書きする（履歴は保持しない）。
表の上の「実行日・実行環境」の行も更新する。

- PASS: `PASS (YYYY-MM-DD)`
- FAIL: `FAIL (YYYY-MM-DD): <失敗内容の要約>（[証跡](screenshots/<ファイル名>)）`
- SKIP: `SKIP (YYYY-MM-DD): 前提条件未成立（No.X FAIL）`

`test-case.md` を保存する。

---

## ステップ6: 実行サマリの報告

チャット上に以下を日本語でまとめる。

- 今回追加・更新したテストケース（ステップ1で変更があった場合。なければ「変更なし」と明記）
- 対象範囲（No.）と実行環境（デバイス名・iOS バージョン）
- 結果件数（PASS / FAIL / SKIP）
- FAIL・SKIP したケースの一覧（No. / 目的 / 失敗内容 / 証跡パス）

出力フォーマット例:

```
## リグレッションテスト実行結果（2026-10-09）

### テストケースの更新
- No.22 を追加（新規設定項目 XxxSettings 対応）

### 実行結果（全21件 / iPhone 17・iOS 26.0）
PASS: 19 / FAIL: 1 / SKIP: 1

| No. | 目的 | 結果 |
|-----|------|------|
| 13 | 録音ファイルの保存 | FAIL: 「録音停止」後もプレイリストに行が追加されない |
| 15 | 再生 | SKIP: 前提条件未成立（No.13 FAIL） |
```
