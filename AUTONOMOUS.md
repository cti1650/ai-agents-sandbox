# 自律実行ガイド

AIエージェントを承認なしで長時間実行するためのガイドです。

## 概要

このDevContainer環境は、AIエージェントの**自律実行**に最適化されています：

- **tmux**: ターミナルを閉じてもプロセスが継続
- **bypassPermissions**: コンテナ内は承認なしで実行（セキュリティはコンテナ隔離で担保）
- **セキュリティ**: 危険な操作は`deny`ルールでブロック

## クイックスタート

### 1. スリープ防止（ホスト側で実行）

**macOS:**
```bash
caffeinate -di &
```

**Windows (PowerShell 管理者):**
```powershell
# フタを閉じても動作継続
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setactive SCHEME_CURRENT
```

**Windows (PowerToys):**
```powershell
PowerToys.Awake.exe --display-on
```

### 2. DevContainer起動

VS Code で「**Dev Containers: Reopen in Container**」を実行

### 3. tmuxセッション開始

```bash
# 基本的な使い方
./scripts/start-session.sh

# セッション名を指定
./scripts/start-session.sh feature-auth

# タスク説明付き
./scripts/start-session.sh bugfix "ログインバグを修正して"
```

### 4. ターミナルを閉じる

`Ctrl+b` → `d` でデタッチ（tmuxセッションは継続）

### 5. 後で再接続

```bash
tmux attach -t ai-agent
```

## tmux基本操作

| 操作 | キー |
|------|------|
| デタッチ（セッション維持） | `Ctrl+b` → `d` |
| ウィンドウ作成 | `Ctrl+b` → `c` |
| ウィンドウ切替 | `Ctrl+b` → `数字` |
| ペイン分割（横） | `Ctrl+b` → `|` |
| ペイン分割（縦） | `Ctrl+b` → `-` |
| ペイン移動 | `Alt` + 矢印キー |
| スクロール | `Ctrl+b` → `[`、`q`で終了 |
| 設定リロード | `Ctrl+b` → `r` |

## 複数エージェント運用

「1ウィンドウ = 1タスク = 1ブランチ」ルールを推奨：

```bash
# ウィンドウ1: Claude Codeで機能開発
tmux new-window -t ai-agent -n "feature"
git checkout -b feat/new-feature
claude "新機能を実装して"

# ウィンドウ2: Codex CLIでバグ修正
tmux new-window -t ai-agent -n "bugfix"
git checkout -b fix/login-bug
codex "ログインバグを修正して"

# ウィンドウ3: Antigravity CLIでリファクタリング
tmux new-window -t ai-agent -n "refactor"
git checkout -b refactor/cleanup
agy "コードをリファクタリングして"
```

### Claude Code を「司令塔」にして分業する

上記のように各 CLI を人が個別に起動する運用に加え、**Claude Code から Codex / Antigravity を
呼び出して分業**させることもできます。リポジトリルートの [`.claude/`](.claude/README.md) に
Skill / SubAgent を用意済みです。

```bash
# Claude Code に統合役をさせ、自己完結タスクを他モデルへ委譲
claude "認証まわりは codex-cli サブエージェントに実装させ、UIは自分で進めて。最後に external-review で突き合わせて。"
```

- Skill: `ask-codex` / `ask-antigravity`（相談・委譲）、`external-review`（多重レビュー）
- SubAgent: `codex-cli` / `antigravity-cli`（独立コンテキストでの分業）
- **競合回避**: 「1タスク = 1担当」を守り、同じファイルを複数エージェントが同時編集しないこと。

> **エージェント向けの共通ルール**（禁止操作・CI/ピン留め・ワークフロー）は、リポジトリルートの
> [`AGENTS.md`](AGENTS.md) に一元化しています（Claude=[`CLAUDE.md`](CLAUDE.md) / agy=[`GEMINI.md`](GEMINI.md)
> が `@AGENTS.md` で取り込み）。自律実行前に各エージェントがこれを読む前提です。

## セキュリティ設定

各AIツールには、コンテナ専用の自律実行設定が用意されています:

| ツール | 設定ファイル | 自律実行モード |
|--------|-------------|----------------|
| Claude Code | `.devcontainer/claude-settings.json` | `bypassPermissions` |
| Codex CLI | `.devcontainer/codex-config.toml` | `approval_policy = "never"` |
| Antigravity CLI | `.devcontainer/antigravity-settings.json` | `toolPermission: "always-proceed"` |

### 許可されない操作（deny）

全ツール共通で以下の操作がブロックされます:

- 機密ファイル（`.env`, `secrets/`, `*.pem`, `*.key`等）の読み取り
- 破壊的コマンド（`rm -rf /`, フォークボム等）
- 危険なスクリプト実行（`curl | bash`等）
- 強制プッシュ（`git push --force`）
- `sudo` コマンド
- パッケージ公開（`npm publish`等）
- Git履歴の破壊（`git reset --hard`, `git clean -fd`）

### その他の操作

自律実行モードにより、上記以外は**承認なしで実行**されます。

## トラブルシューティング

### セッションが見つからない

```bash
# 全セッション一覧
tmux list-sessions

# セッションが存在するか確認
tmux has-session -t ai-agent && echo "存在" || echo "なし"
```

### スクロールバックを見たい

```bash
# tmux内で
Ctrl+b → [

# 矢印キーやPage Up/Downでスクロール
# qで終了
```

### セッションを終了したい

```bash
# 特定のセッションを終了
tmux kill-session -t ai-agent

# 全セッションを終了
tmux kill-server
```

### VS Codeから切断された

tmuxセッション内のプロセスは継続しています：

```bash
# ホストから直接コンテナに接続
docker exec -it <container-id> bash

# tmuxセッションに再接続
tmux attach -t ai-agent
```

## 熱管理の注意

ノートPCのフタを閉じた状態での長時間実行は**熱問題**のリスクがあります：

- 通気性の良い場所に設置
- 外部モニター接続時はクラムシェルモードを検討
- 定期的に温度を確認

## 参考リンク

- [tmux cheat sheet](https://tmuxcheatsheet.com/)
- [Claude Code Permissions](https://docs.anthropic.com/claude-code/permissions)
