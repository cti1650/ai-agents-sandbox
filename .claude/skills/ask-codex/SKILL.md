---
name: ask-codex
description: |
  OpenAI の Codex CLI (`codex`) にセカンドオピニオンや実装を委譲するスキル。
  トリガー条件:
  - 「Codex に聞いて」「GPT の意見も」「OpenAI で確認して」
  - 難しい設計判断・バグ調査で別モデルの視点が欲しいとき
  - あるモジュールの実装を Codex に分業させたいとき（並列実装）
  - 「codex に投げて」「codex で実装して」
---

# ask-codex — Codex CLI に相談・委譲する

Claude 自身とは別の推論エンジン（OpenAI 系モデル）である Codex CLI を呼び出し、
セカンドオピニオンを得たり、独立した実装タスクを分業させたりするためのスキル。

## いつ使うか

- **セカンドオピニオン**: 設計方針・バグの原因・アルゴリズム選定などで、Claude の結論を
  別モデルで裏取りしたいとき。
- **分業/並列実装**: Claude が別の作業に集中している間に、自己完結したモジュールの実装を
  Codex に任せたいとき。
- ユーザーが明示的に「Codex に聞いて / 実装させて」と言ったとき。

> クロス検証（Claude・Codex・Antigravity の三者を突き合わせる）が目的なら、必要に応じて
> このスキルと [ask-antigravity](../ask-antigravity/SKILL.md) を併用する。

## 前提

- 実行環境は DevContainer（コンテナ隔離でセキュリティを担保）。
- `~/.codex/config.toml` は `approval_policy = "never"` / `sandbox_mode = "workspace-write"`
  済みなので、`codex exec` は承認プロンプトなしで走る。
- 認証: `OPENAI_API_KEY`（`.env` 経由）または `codex login`。未認証だと Codex がサインインを
  促すので、その旨をユーザーに伝える。

## 使い方

### 1. セカンドオピニオン（読み取り専用で意見だけもらう）

Codex に**ファイルを書き換えさせず**意見だけ求める場合は `--sandbox read-only` を付ける。

```bash
codex exec --sandbox read-only "次の設計についてレビューして。懸念点と代替案を3つまで挙げて。<設計の要約や対象ファイルを具体的に記述>"
```

- プロンプトには「何を・どのファイルを・何の観点で」見てほしいかを具体的に書く。
- 出力は stdout に返る。**Claude はそれを鵜呑みにせず**、自分の見解と突き合わせて
  「一致点 / 相違点 / 最終判断」を要約してユーザーに提示する。

### 2. 分業（実装を委譲する）

自己完結したタスクを丸ごと任せる場合。ワークスペースへの書き込みは設定済み。

```bash
codex exec "src/foo モジュールに <仕様> を実装して。既存の <規約> に合わせること。完了したら変更点を要約して。"
```

- **競合回避**: Codex が触るファイル範囲を Claude が同時に編集しないこと。1タスク=1担当を守る。
- 実行後は `git diff` で Codex の変更を確認し、Claude がレビューしてから統合する。
- 長い作業は `codex exec` が完走するまで待つ（`--print-timeout` 相当の待ちが要る場合あり）。

### 3. 特定ディレクトリを作業根にする

```bash
codex exec -C <dir> --sandbox read-only "..."
```

## 出力の扱い（重要）

- Codex の回答は**参考意見**。Claude が最終責任を持ち、必ず検証してから採用する。
- 相違があれば「Codex はこう言ったが、根拠 X により自分はこう判断する」と明示する。
- そのまま貼り付けず、要点を日本語で整理してユーザーに返す。

## トラブルシューティング

- `Please sign in` / 認証エラー → `OPENAI_API_KEY` を `.env` に設定するか `codex login` が必要。
  ユーザーに案内する（Claude が代理ログインはしない）。
- Git リポジトリ外エラー → `--skip-git-repo-check` を付ける。
