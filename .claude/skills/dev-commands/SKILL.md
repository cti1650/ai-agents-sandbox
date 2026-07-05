---
name: dev-commands
description: |
  このリポジトリの定型コマンド（環境検証・セットアップ・secretlint 等）を実行するスキル。
  トリガー条件:
  - 「環境を検証して」「verify を回して」「セットアップして」
  - 「secretlint かけて」「シークレット走査して」
  - 「開発コマンドを実行して」「このリポジトリの決まったコマンドを打って」
  - DevContainer 初期化直後の健全性確認や、コミット前のローカルチェック
---

# dev-commands — リポジトリ定型コマンド実行

AI Agents Sandbox でよく使う環境検証・セットアップ・チェック系コマンドを、正しい引数・
実行場所で叩くためのスキル。ワンオフの調査コマンドではなく、**このリポジトリで決まっている
手順**を対象にする。

## 前提

- 実行は DevContainer 内（コンテナ隔離でセキュリティ担保）。
- リポジトリルートは git ルート（`/workspaces/ai-agents-sandbox`）。スクリプトはルート基準で叩く。
- パッケージ導入は Takumi Guard 経由（`.npmrc` / `pip.conf` / `~/.config/uv/uv.toml`）。索引設定を外さない。
- 破壊的コマンドは [AGENTS.md](../../../AGENTS.md) の禁止操作に従い実行しない。

## 環境検証・セットアップ

### 環境検証（最初にこれ）

ツール・Python/pip/uv の索引・シークレットスキャナ等をまとめて確認する。

```bash
bash scripts/verify.sh
```

- `[OK]` / `[WARN]` で結果が出る。WARN が出たら原因（設定ファイル・環境変数）を調べてから対処する。

### 依存関係のインストール / フック導入

```bash
npm install          # devDependencies 導入 + "prepare" で lefthook install も走る
npx lefthook install # git hooks を明示的に入れ直したいとき
```

### 自律実行セッション（tmux）

```bash
bash scripts/start-session.sh                 # 既定セッション
bash scripts/start-session.sh <name> "<task>" # 名前・タスク説明付き
```

詳細は [AUTONOMOUS.md](../../../AUTONOMOUS.md)。

## よく使う開発コマンド

### シークレット走査（コミット前チェック）

```bash
npm run secretlint                              # secretlint: 全ファイルを走査
npx --no-install secretlint --maskSecrets <file># secretlint: 特定ファイルだけ
gitleaks detect --source .                      # gitleaks: 履歴も含めて走査（CI と同じ）
```

- pre-commit（lefthook）は **secretlint のみ**をステージ済みファイルに対して自動実行する。
- **gitleaks は CI（`gitleaks-scan.yml`）で走る**が pre-commit では走らない。履歴ごと確認したいときは手動で。

### GitHub Actions のピン留め検査

workflow（`.github/workflows/*.yml`）を新規/編集したら、SHA ピン留めを確認する。未ピン・
コメント不一致は `pin-check.yml` が CI を落とす。

```bash
git diff --stat .github/workflows/          # 変更対象の確認
# 各 uses: が `@<40桁SHA> # vX.Y.Z` 形式か、コメントの版と SHA が一致しているかを確認する
```

### Git 状態確認

```bash
git status -sb && git diff --stat
```

### 通知（タスク完了・入力待ち）

```bash
bash scripts/notify.sh stop            # 完了通知（ベル / VS Code タブ / Slack）
bash scripts/notify.sh stop noslack    # Slack を抑制
```

## 進め方の原則

1. **まず `scripts/verify.sh`** で環境が健全か確認する。
2. コマンドの出力（特に WARN / エラー）を鵜呑みにせず、原因を特定してから次に進む。
3. 結果は要点を日本語で整理して報告する（生ログの丸貼りをしない）。
4. コミット・プッシュ・PR はユーザーが明示的に指示したときだけ行う。
