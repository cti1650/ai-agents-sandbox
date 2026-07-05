# CLAUDE.md — Claude Code 向けルール

プロジェクト共通の作法は [AGENTS.md](AGENTS.md) に集約しています。まずそちらを読んでください。

@AGENTS.md

> `workspace/` でコード（JS/TS/Python 等）を書くときの汎用コード規約は
> [`.claude/rules/coding.md`](.claude/rules/coding.md) にあります。`.claude/rules/` は Claude Code が
> **起動時に自動読み込み**するため `@import` は不要です（各プロジェクト側の設定・慣習があればそちらが優先）。

---

## Claude Code 固有メモ

- 外部モデルへの委譲・多重レビューは [`.claude/`](.claude/README.md) の Skill / SubAgent を使う:
  - Skill: `ask-codex` / `ask-antigravity`（相談・委譲）、`external-review`（現在の diff を多重レビュー）
  - SubAgent: `codex-cli` / `antigravity-cli`（独立コンテキストで自己完結タスクを分業）
- リポジトリ定型コマンド（環境検証・セットアップ・よく使う開発コマンド）は Skill `dev-commands` にまとめてある。
- 自分の変更レビューは Claude の `/code-review`、外部モデルとの突き合わせは `external-review` を併用する。
- `codex` / `agy` の実行は [`.claude/settings.json`](.claude/settings.json) で allow 済み。

### 導入済みプラグイン skill

[`.devcontainer/claude-settings.json`](.devcontainer/claude-settings.json) で以下を有効化済み。該当作業では優先して使う:

- **dev-workflow-skills**（`cti1650/dev-workflow-skills`）… `commit-push` / `feature-pr` / `review-pr` /
  `dep-upgrade`。コミット〜PR やパッケージ更新の定型フロー。
- **dev-security-skills**（同上）… `dep-audit`（npm/pip audit の解消）/ `dep-review`（Dependabot/Renovate PR の影響分析）。
- **cosense-cli**（`helpfeel/cosense-cli`）… Cosense（Scrapbox）ページの読み書き。
