# AI Agents Sandbox

セキュアなDevContainer環境でAIコーディングエージェント（Claude Code, Codex CLI, Antigravity CLI）を実行するためのプロジェクト。

## 含まれるツール

| ツール | コマンド | 提供元 |
|--------|----------|--------|
| Claude Code | `claude` | Anthropic |
| Codex CLI | `codex` | OpenAI |
| Antigravity CLI | `agy` | Google |

## 必要要件

- Docker Desktop
- Visual Studio Code
- [Dev Containers拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## セットアップ

### 1. 環境変数の設定

プロジェクトルートに`.env`ファイルを作成し、APIキーを設定:

```bash
ANTHROPIC_API_KEY=sk-ant-xxxxx
OPENAI_API_KEY=sk-xxxxx
GOOGLE_API_KEY=xxxxx
```

### 2. ホスト設定のマウント

ローカルマシンの以下のディレクトリがコンテナにマウントされます（読み取り専用）:

- `~/.ssh` - SSHキー（Git操作用）
- `~/.gitconfig` - Git設定

各AIツールの認証はコンテナ内で個別に行ってください。

### 3. DevContainerの起動

1. VSCodeでこのフォルダを開く
2. コマンドパレット（Cmd+Shift+P）を開く
3. 「Dev Containers: Reopen in Container」を選択

## セキュリティ設定

このsandbox環境には以下のセキュリティ対策が施されています:

- 非rootユーザーでの実行
- 不要なLinux capabilitiesの削除
- 特権昇格の禁止（no-new-privileges）
- リソース制限（メモリ8GB、CPU 4コア）
- ホスト設定の読み取り専用マウント

## 使用方法

```bash
# Claude Code
claude

# Codex CLI
codex

# Antigravity CLI
agy
```

## トラブルシューティング

### APIキーが認識されない

`.env`ファイルが正しく設定されているか確認し、コンテナを再ビルド:

```bash
# VSCodeコマンドパレットから
Dev Containers: Rebuild Container
```
