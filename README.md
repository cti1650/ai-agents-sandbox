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

macOS / Windows のどちらでも、**事前準備なし**で動作します（Git/SSH は VS Code が自動共有）。改行コードは `.gitattributes` でLFに正規化しているため、Windows でクローンしてもスクリプトは壊れません。

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

3. **環境変数（任意）**
   ```bash
   cp .env.example .env      # 必要なら API キーを記入（任意）
   ```
   事前準備はこれだけです。SSHキーやGit設定の手動作成は不要です（後述の「Git / SSH の共有」を参照）。

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

4. **環境変数（任意・WSL ターミナル内で実行）**
   ```bash
   cp .env.example .env
   ```
   事前準備はこれだけです。SSHキーやGit設定の手動作成は不要です。

5. **コンテナで開く**
   ```bash
   code .
   ```
   VS Code が WSL に接続して起動します。`Ctrl+Shift+P` →「**Dev Containers: Reopen in Container**」を選択。

### Git / SSH の共有について

ホストの `~/.ssh` や `~/.gitconfig` は**マウントしません**。VS Code Dev Containers が以下を自動で行うため、**事前準備は不要**です:

- **Git設定** … ホストの `~/.gitconfig`（ユーザー名・メール等）を自動でコンテナに反映
- **SSH** … ホストで起動中の **SSHエージェントを自動フォワード**（鍵をコンテナにコピーしません）

> Git を SSH（`git@github.com:...`）で使う場合は、ホストの **ssh-agent に鍵が登録**されている必要があります（macOS は Keychain 連携で通常自動登録、Windows は `OpenSSH Authentication Agent` サービスを有効化）。HTTPSリモートの場合は VS Code の資格情報共有が使われます。
>
> この方式により、空ファイルの事前作成や macOS の `UseKeychain` 回避は不要になりました。

### AI CLI 設定の共有

各AIツールのホスト設定がコンテナにマウントされます（読み取り専用）:

#### Claude Code (`~/.claude/`)

| ファイル/ディレクトリ | 用途 |
|----------------------|------|
| `skills/` | カスタムスキル |
| `agents/` | カスタムサブエージェント |
| `rules/` | ユーザーレベルルール |
| `commands/` | レガシーコマンド |
| `workflows/` | 動的ワークフロースクリプト |
| `output-styles/` | カスタム出力フォーマット |
| `themes/` | カスタムカラーテーマ |
| `keybindings.json` | キーボードショートカット |
| `CLAUDE.md` | 個人用グローバル指示 |

#### Codex CLI (`~/.codex/`)

| ファイル/ディレクトリ | 用途 |
|----------------------|------|
| `AGENTS.md` | グローバル指示 |
| `skills/` | カスタムスキル |
| `plugins/` | プラグイン |
| `rules/` | 実行ポリシールール |

#### Antigravity CLI (`~/.gemini/`)

| ファイル/ディレクトリ | 用途 |
|----------------------|------|
| `GEMINI.md` | グローバルルール |
| `AGENTS.md` | クロスツール共有ルール |
| `config/` | 共有MCP設定 |
| `skills/` | 全ツール共有スキル |
| `antigravity-cli/keybindings.json` | キーバインド |
| `antigravity-cli/skills/` | CLI専用スキル |
| `antigravity-cli/plugins/` | プラグイン |

**認証データは別管理**: 認証情報は named volume に保存されるため、設定の共有とは独立しています。初回のみコンテナ内で `/login` が必要ですが、以降はコンテナを再ビルドしても認証が維持されます。

> **Note**: 各ツールの設定ファイル（Claude Code の `settings.json`、Codex CLI の `config.toml`、Antigravity CLI の `settings.json`）はコンテナにマウントされません。コンテナ内では自律実行用の専用設定（`.devcontainer/` 配下）が使用されます。

> シンボリックリンク（dotfiles等）は Docker が自動的に解決します。

## VS Codeの日本語化

DevContainer起動時に、日本語言語パック拡張機能（`MS-CEINTL.vscode-language-pack-ja`）が自動でインストールされ、表示言語が日本語（`locale: ja`）に設定されます。初回はVS Codeから再起動を促されるので、表示に従って「**Restart**」を選択してください。

英語表示に戻したい場合は `Cmd/Ctrl+Shift+P` →「**Configure Display Language**」から `en` を選択します。

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
- リソース制限（メモリ4GB、CPU 2コア、プロセス数256）
- コンテナヘルスチェック（30秒間隔）
- ホストSSH鍵をコンテナへ展開せず、SSHエージェント転送を利用（VS Code 自動共有）
- 多層シークレットスキャン:
  - [secretlint](https://github.com/secretlint/secretlint): APIキー・トークンの検出
  - [gitleaks](https://github.com/gitleaks/gitleaks): Git履歴とステージ変更のスキャン
- npmサプライチェーン対策（`.npmrc`）:
  - [Takumi Guard](https://shisho.dev/docs/ja/t/guard/quickstart/npm/)（匿名モード）で悪性パッケージをインストール前にブロック
  - `min-release-age=3` で公開3日未満のバージョンを隔離（要 npm 11.10.0+）
- PyPIサプライチェーン対策（`pip.conf`, `PIP_CONFIG_FILE`で適用）:
  - [Takumi Guard for PyPI](https://shisho.dev/docs/ja/t/guard/quickstart/pypi/)（匿名モード）で悪性パッケージをブロック
  - プロキシ側で新規公開バージョンを**自動で72時間（3日）隔離**（pip側の追加設定は不要）

詳細は [SECURITY.md](SECURITY.md) を参照してください。

> Python は `python` / `python3` の両方で実行可能（`python-is-python3` 導入済み）。
> パッケージ導入は PEP 668 のため venv 推奨: `python3 -m venv .venv && source .venv/bin/activate`

## 使用方法

### 作業ディレクトリ

DevContainer起動時、VS Codeは **`workspace/`** フォルダを直接開きます。このフォルダは親リポジトリのGit管理外なので、自由にファイルを作成・編集できます。

```bash
# 現在地は workspace/ フォルダ
pwd  # /workspaces/ai-agents-sandbox/workspace

# リポジトリルート（README等）にアクセスする場合
cd $REPO_ROOT
# または
cd ..
```

#### workspace/ を別リポジトリとして管理する

workspace/ 内で独自のGitリポジトリを初期化できます。これによりファイルがグレーアウトせず、通常のGit管理が可能になります。

```bash
# workspace/ 内で新規リポジトリを初期化
git init
git remote add origin git@github.com:username/my-project.git

# または既存リポジトリをクローン
cd ..
rm -rf workspace
git clone git@github.com:username/my-project.git workspace
```

> **セキュリティ**: グローバルgit hooks（`~/.config/git/hooks/pre-commit`）が設定されており、workspace/内のリポジトリでもコミット時にsecretlintが自動実行されます。APIキーやトークンの誤コミットを防止します。

### AI CLIの実行

```bash
# Claude Code
claude

# Codex CLI
codex

# Antigravity CLI
agy
```

### 自律実行モード（Autonomous Mode）

このDevContainer環境は、AIエージェントの**自律実行**に最適化されています。ターミナルを閉じてもAIが作業を継続できます。

#### クイックスタート

1. **スリープ防止（ホスト側）**
   ```bash
   # macOS
   caffeinate -di &

   # Windows (PowerShell 管理者)
   powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
   powercfg /setactive SCHEME_CURRENT
   ```

2. **tmuxセッション開始**
   ```bash
   ./scripts/start-session.sh              # デフォルトセッション
   ./scripts/start-session.sh feature-auth # 名前付きセッション
   ```

3. **デタッチ**: `Ctrl+b` → `d`（セッション継続したままターミナルを閉じる）

4. **再接続**: `tmux attach -t ai-agent`

#### コンテナ専用の自律実行設定

コンテナ内では各ツールが自律実行モードで動作し、ほとんどの操作が承認なしで実行されます:

| ツール | モード |
|--------|--------|
| Claude Code | `bypassPermissions` |
| Codex CLI | `approval_policy = "never"` |
| Antigravity CLI | `toolPermission: "always-proceed"` |

セキュリティはコンテナの隔離環境と `deny` ルール（機密ファイル読取、破壊的コマンド、sudo等のブロック）で担保されます。

詳細は [AUTONOMOUS.md](AUTONOMOUS.md) を参照してください。

### DevContainerの終了

コンテナを閉じるには以下のいずれかを実行:

1. **ローカルに戻る**: `Cmd/Ctrl+Shift+P` →「**Dev Containers: Reopen Folder Locally**」
2. **VS Code を閉じる**: ウィンドウを閉じるだけでOK（コンテナは停止します）
3. **コンテナを完全削除**: `Cmd/Ctrl+Shift+P` →「**Dev Containers: Rebuild Container**」（次回起動時に再ビルド）

> コンテナを閉じても、AI ツールの認証データは named volume に保存されているため消えません。

## トラブルシューティング

### APIキーが認識されない

`.env`ファイルが正しく設定されているか確認し、コンテナを再ビルド:

```bash
# VSCodeコマンドパレットから
Dev Containers: Rebuild Container
```

### Git の SSH 認証がうまくいかない

事前準備不要の構成では、Git over SSH は**ホストの ssh-agent 転送**を使います。`git pull` / `push` が認証エラーになる場合:

1. **ホスト側（コンテナの外）で鍵がエージェントに登録されているか確認:**
   ```bash
   ssh-add -l        # 鍵が表示されればOK。空なら下記で追加
   ```
   - macOS: `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`（Keychain 連携で次回以降も自動）
   - Windows: サービス「**OpenSSH Authentication Agent**」を「自動」起動にして `ssh-add`

2. **それでも解決しない場合は HTTPS + GitHub CLI（鍵不要）:**
   ```bash
   gh auth login            # ブラウザ認証
   gh auth setup-git        # gh を Git の資格情報ヘルパーに設定
   git remote set-url origin https://github.com/<owner>/<repo>.git
   ```

## ライセンス

[MIT License](LICENSE) のもとで公開しています。
