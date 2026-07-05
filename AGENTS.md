# AGENTS.md — 共通エージェント作法（唯一の正）

このファイルは **Claude Code / Codex CLI / Antigravity CLI 共通**のプロジェクト作法です。
- **Codex CLI (`codex`)** … このファイルをネイティブに読み込みます。
- **Antigravity CLI (`agy`)** … このファイルをネイティブに読み込みます。
- **Claude Code (`claude`)** … [`CLAUDE.md`](CLAUDE.md) が `@AGENTS.md` で取り込みます。

> ルール本体はここ **1か所**に集約します。ツール固有の追記だけを各 `CLAUDE.md` / `GEMINI.md`
> 側に書き、内容の重複を避けてください。

## プロジェクト概要

セキュアな DevContainer 環境で AI コーディングエージェント（Claude Code / Codex CLI /
Antigravity CLI）を実行するためのサンドボックス。リポジトリ本体は「devcontainer の土台 +
シークレット走査 + git hooks」が中心で、実作業は gitignore 対象の `workspace/` で行います。

- 主要ドキュメント: [README.md](README.md) / [SECURITY.md](SECURITY.md) / [AUTONOMOUS.md](AUTONOMOUS.md)
- 対象ツール: `claude`（Anthropic）/ `codex`（OpenAI）/ `agy`（Google）

## 使用言語

- **ユーザーとのやり取り・コミットメッセージ・PR・コメントは日本語**（既存ファイルの語調に合わせる）。
- コード内の識別子や技術用語は無理に訳さない。

## 実行環境とセキュリティモデル

- すべての作業は **DevContainer 内**で行う。セキュリティは**コンテナ隔離**で担保する前提。
- 各ツールはコンテナ内で自律実行モード（Claude=`bypassPermissions` / Codex=`approval_policy=never` /
  agy=`always-proceed`）。承認プロンプトなしで走るぶん、**下記の禁止操作は自分で守る**こと。
- **禁止操作（全ツール共通・deny 相当）** — 詳細は [AUTONOMOUS.md](AUTONOMOUS.md) / [SECURITY.md](SECURITY.md):
  - 機密ファイル（`.env`, `secrets/`, `*.pem`, `*.key` 等）の読み取り
  - 破壊的コマンド（`rm -rf /`、フォークボム等）、`curl | bash` 等の危険スクリプト実行
  - `git push --force`、`git reset --hard`、`git clean -fd` などの履歴・作業破壊
  - `sudo`、`npm publish` 等のパッケージ公開
  - この deny リストは **3ツール同一ポリシー**（Claude=`claude-settings.json` /
    Codex=`codex-config.toml` / agy=`antigravity-settings.json`）で揃えてある。
- **deny ルールは「境界」ではなく「補助策」**。うっかり事故を減らすためのパターンマッチであり、
  シェル経由・別名・インタプリタ経由で原理的に回避されうる。**過信せず、そもそも危険操作をしない**
  こと。実効的な安全は隔離・権限境界（非root + `no-new-privileges` + `cap_drop`）が担う（[SECURITY.md](SECURITY.md)）。
- **パッケージインストールは Takumi Guard 経由**（悪性パッケージのブロック + 新規公開の 72h 隔離）:
  - npm … `.npmrc`、pip … `pip.conf`（`PIP_CONFIG_FILE` 経由）、uv … `~/.config/uv/uv.toml`。
  - これらの索引設定（`registry` / `index-url`）を勝手に外さない。
- **egress（外向き通信）制御は無い前提**。`iptables` / `ipset` 等の firewall を勝手に足さない
  （壊れやすく、失敗するとコンテナに接続できなくなる）。強い制御が要る場合はホスト/ネットワーク層で行う。
- **認証は任意**。API キー（`.env` の `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GOOGLE_API_KEY`）か、
  各 CLI の対話ログインのどちらか。未認証エラー時は**代理ログインせず**、ユーザーに案内する。

## 開発ワークフロー

- **1 タスク = 1 ブランチ = 1 担当**。複数エージェントが同じファイルを同時編集しない（競合回避）。
- ブランチ名規約: `feature/` `fix/` `docs/` `refactor/`。
- **main / master へ直接コミットしない**。作業前にブランチを切る。
- **コミット・プッシュ・PR 作成はユーザーが明示的に指示したときだけ**行う。
- コミットは Conventional Commits 風（`fix:` `feat:` `docs:` `ci:` `refactor:` …）+ 日本語の要約。
- pre-commit で **secretlint** がステージ済みファイルを走査（lefthook 管理）。シークレットを含めない。
- 変更後は環境検証スクリプトで健全性を確認できる: `bash scripts/verify.sh`。

## CI・ピン留め・依存関係

CI で自動チェックされるため、以下を破ると PR が赤くなりマージできない。ローカルで先に守ること。

- **`scripts/verify.sh` は CI のスモークテスト**（`devcontainer-ci.yml`）。ツール・索引・スキャナ設定を
  検証する。**プッシュ前にローカルで通す**。赤いままにしない。
- **GitHub Actions は必ず commit SHA でピン留め**し、`# vX.Y.Z` コメントを SHA と一致させる
  （`pin-check.yml` / `pinact` が未ピン・不一致で CI を落とす）。workflow を新規/編集したら必ず守る。
- **ベースイメージ・CLI のバージョン固定を外さない**。ベースイメージは `@sha256:` ダイジェスト固定、
  Dockerfile 内 CLI はバージョンピン。更新は Dependabot に任せる（[SECURITY.md](SECURITY.md) サプライチェーン対策）。
- **シークレット走査は2層**：pre-commit=**secretlint**（ステージ済みのみ）、CI=**gitleaks**（`gitleaks-scan.yml`、
  全履歴）。gitleaks はローカルの pre-commit では走らないので、必要なら手動で `gitleaks detect --source .`。

## 主要ファイル / スクリプト

| パス | 役割 |
|---|---|
| `scripts/verify.sh` | 環境・ツール・セキュリティ設定の検証 |
| `scripts/start-session.sh` | tmux 自律実行セッションの開始 |
| `scripts/notify.sh` | タスク完了・入力待ちの通知（ベル / VS Code タブ / Slack） |
| `scripts/post-create.sh` | devcontainer postCreate 処理 |
| `.devcontainer/` | コンテナ定義・各ツールの自律実行設定 |
| `.claude/` | Claude Code から codex/agy を呼ぶ Skill / SubAgent 一式 |

## マルチエージェント連携

- Claude Code を司令塔に、自己完結タスクを Codex / Antigravity へ委譲できる（[.claude/README.md](.claude/README.md)）。
- 他モデルの出力は**参考意見**。呼び出し元が検証してから採用する。
- 委譲時は「触るファイル範囲」を明確にし、並列作業の競合を避ける。
