---
name: ios-release-prep
description: リリース前の準備作業（バージョン確認・ストア向けリリースノート作成・保存）を行う [iOS編]
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Grep
---

# リリース準備タスク

以下の手順を順番に実施してください。

---

## ステップ 1: バージョン確認とユーザー確認

### 1-1. 現在のブランチのバージョン取得

`project.pbxproj` を読み込み、現在の `MARKETING_VERSION` と `CURRENT_PROJECT_VERSION` を取得する。

### 1-2. main ブランチのバージョン取得

以下を実行して main ブランチの `MARKETING_VERSION` と `CURRENT_PROJECT_VERSION` を取得する：

```bash
git show refs/heads/main:shinobuetuner.xcodeproj/project.pbxproj | grep -E 'MARKETING_VERSION|CURRENT_PROJECT_VERSION'
```

### 1-3. ユーザーに確認

以下の形式で両バージョンを提示し、「このバージョンで問題ありませんか？」と確認する：

```
現在のブランチ : MARKETING_VERSION = X.X.X, CURRENT_PROJECT_VERSION = N
main ブランチ  : MARKETING_VERSION = X.X.X, CURRENT_PROJECT_VERSION = N
```

ユーザーが問題ないと回答したら、ステップ 2 に進む。

---

## ステップ 2: 前回リリースとの差分確認

以下を実行して前回リリース以降の変更内容を把握する：

```bash
# 最新のリリースタグを取得
gh release list --limit 1

# 前回タグ以降のマージコミットを取得（タグ名と同名ブランチが存在する場合は refs/tags/ を明示）
git log refs/tags/<前回タグ>..HEAD --oneline --merges
```

各マージコミットから `gh pr view <PR番号>` でタイトルと URL を取得する。

---

## ステップ 3: ストア向けリリースノートの作成

### 3-1. 下書きの提示

変更内容を元に、**エンドユーザー向け**のリリースノート下書きを提示する。

- 技術的な内容は平易な言葉に言い換える
- PR タイトルや URL は含めない
- 箇条書きで簡潔に（例: 「・○○機能を追加」「・○○の不具合を修正」）
- 1項目は20〜30字以内を目安にする
- 詳細な説明は不要。機能名と「追加」「改善」「修正」などの動詞だけで十分

### 3-2. ユーザーに内容を確認・修正してもらう

下書きをユーザーに提示し、「このリリースノートで OK ですか？修正があれば教えてください」と確認する。

### 3-3. ファイルへの保存

ユーザーが確定した内容を以下のパスに保存する：

```
metadata/release-notes/<versionName>.md
```

ファイルの内容フォーマット：

```markdown
# <versionName> リリースノート

## App Store 掲載文

・<変更内容1>  
・<変更内容2>  
・<変更内容3>  
```

---

## ステップ 4: 確認チェックリスト

以下の項目を確認してユーザーに提示する：

- [ ] `MARKETING_VERSION` が正しいか
- [ ] `CURRENT_PROJECT_VERSION` が前回から +1 されているか
- [ ] ストア向けリリースノートに漏れがないか
