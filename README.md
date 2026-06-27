# AI Agents Sandbox

セキュアなDevContainer環境でAIコーディングエージェント（Claude Code, Codex CLI, Antigravity CLI）を実行するためのプロジェクト。

## 含まれるツール

| ツール | コマンド | 提供元 |
|--------|----------|--------|
| Claude Code | `claude` | Anthropic |
| Codex CLI | `codex` | OpenAI |
| Antigravity CLI | `agy` | Google |

## 必要要件

- Docker Desktop（**4GB以上のメモリ割当**を推奨。低スペック端末でも動くよう、`docker-compose.yml` でコンテナに最大メモリ4GB / CPU2コアを割り当てています。余裕がある場合はこの値を上げると高速化します）
- Visual Studio Code
- [Dev Containers拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

macOS / Windows のどちらでも動作します。改行コードは `.gitattributes` でLFに正規化しているため、Windows でクローンしてもスクリプトは壊れません。

## クイックスタート（OS別）

### 🍎 macOS

1. **必要なソフトをインストール**
   - [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)（Apple Silicon / Intel 対応版を選択）
   - [Visual Studio Code](https://code.visualstudio.com/) ＋ [Dev Containers拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   - Docker Desktop の **Settings → Resources** でメモリを **4GB以上** に設定

2. **リポジトリを取得**
   ```bash
   git clone https://github.com/cti1650/ai-agents-sandbox.git
   cd ai-agents-sandbox
   ```

3. **事前準備**（マウント先の用意と環境変数）
   ```bash
   mkdir -p ~/.ssh
   touch ~/.gitconfig        # 無いと Docker がディレクトリ化して Git が壊れる
   cp .env.example .env      # 必要なら API キーを記入（任意）
   ```
   > `~/.ssh/config` に `UseKeychain` がある場合は、`Host *` に `IgnoreUnknown UseKeychain` を追加してください（コンテナ内のLinux SSHは非対応のため）。

4. **コンテナで開く**
   ```bash
   code .
   ```
   VS Code で `Cmd+Shift+P` →「**Dev Containers: Reopen in Container**」を選択。初回はビルドに数分かかり、完了後に `scripts/verify.sh` が自動実行されます。

### 🪟 Windows

> **WSL2 上での利用を強く推奨**します（Windowsファイルシステム上はマウントが遅く、改行コードや権限の問題も起きやすいため）。

1. **WSL2 を有効化**（PowerShell を管理者として実行）
   ```powershell
   wsl --install
   ```
   再起動後、Ubuntu などのディストリビューションが使えるようになります。

2. **必要なソフトをインストール**
   - [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) をインストールし、**Settings → General** で「**Use the WSL 2 based engine**」を有効化
   - **Settings → Resources** でメモリを **4GB以上** に設定
   - [Visual Studio Code](https://code.visualstudio.com/) ＋ [Dev Containers拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

3. **リポジトリを取得**（WSL2 内のホームに置くこと）

   WSL ターミナル（Ubuntu）を開いて:
   ```bash
   git clone https://github.com/cti1650/ai-agents-sandbox.git
   cd ai-agents-sandbox
   ```
   > `C:\...`（Windows側）ではなく WSL2 内（`~/` 配下）に置くとマウントが高速で安定します。

4. **事前準備**（WSL ターミナル内で実行）
   ```bash
   mkdir -p ~/.ssh
   touch ~/.gitconfig
   cp .env.example .env
   ```

5. **コンテナで開く**
   ```bash
   code .
   ```
   VS Code が WSL に接続して起動します。`Ctrl+Shift+P` →「**Dev Containers: Reopen in Container**」を選択。

### ホスト設定のマウントについて

ホストの以下が読み取り専用でコンテナにマウントされます。各AIツールの認証はコンテナ内で個別に行ってください。

- `~/.ssh` - SSHキー（Git操作用）
- `~/.gitconfig` - Git設定

> `.env` は任意です（使うエージェントの分のキーだけでOK）。各CLIはコンテナ内で対話的にも認証できます。

## 検証（Verification）

このリポジトリはDevContainer環境の検証に特化しています。コンテナ生成時に`scripts/verify.sh`が自動実行され、以下を確認します:

- AI CLI（`claude` / `codex` / `agy`）とベースツール（`git` / `gh` / `jq` / `python3` / `node`）の導入
- 非rootユーザー（`vscode`, UID 1000）での実行とワークスペースの書き込み可否
- セキュリティ設定（no-new-privileges、capability削除など）の有効性

手動で実行する場合:

```bash
bash scripts/verify.sh
```

また、GitHub Actions（`.github/workflows/devcontainer-ci.yml`）が push / PR ごとにコンテナをビルドして`verify.sh`を実行するため、コンテナやバンドルしたCLIが壊れるとCIが失敗します。さらに `pin-check.yml` が、GitHub Action がコミットSHAに固定されているか（バージョンコメントとの一致も含めて）を検証します。

## Pre-commitフック（シークレット検査）

[secretlint](https://github.com/secretlint/secretlint) による秘密情報の混入チェックを、[lefthook](https://github.com/evilmartians/lefthook) の pre-commit フックで実行します。`npm install`（DevContainer生成時に自動実行）でフックが設定され、`git commit` 時にステージされたファイルがスキャンされます。

```bash
npm install        # 依存導入 + フック設定（lefthook install）
npm run secretlint # 手動でリポジトリ全体をスキャン
```

APIキーやトークンを誤ってコミットしようとすると、コミットがブロックされます。

## セキュリティ設定

このsandbox環境には以下のセキュリティ対策が施されています:

- 非rootユーザーでの実行
- 不要なLinux capabilitiesの削除
- 特権昇格の禁止（no-new-privileges）
- リソース制限（メモリ4GB、CPU 2コア）
- ホスト設定の読み取り専用マウント
- npmサプライチェーン対策（`.npmrc`）:
  - [Takumi Guard](https://shisho.dev/docs/ja/t/guard/quickstart/npm/)（匿名モード）で悪性パッケージをインストール前にブロック
  - `min-release-age=3` で公開3日未満のバージョンを隔離（要 npm 11.10.0+）
- PyPIサプライチェーン対策（`pip.conf`, `PIP_CONFIG_FILE`で適用）:
  - [Takumi Guard for PyPI](https://shisho.dev/docs/ja/t/guard/quickstart/pypi/)（匿名モード）で悪性パッケージをブロック
  - プロキシ側で新規公開バージョンを**自動で72時間（3日）隔離**（pip側の追加設定は不要）

> Python は `python` / `python3` の両方で実行可能（`python-is-python3` 導入済み）。
> パッケージ導入は PEP 668 のため venv 推奨: `python3 -m venv .venv && source .venv/bin/activate`

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

## ライセンス

[MIT License](LICENSE) のもとで公開しています。
