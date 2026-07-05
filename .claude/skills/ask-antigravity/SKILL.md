---
name: ask-antigravity
description: |
  Google の Antigravity CLI (`agy`) にセカンドオピニオンや実装を委譲するスキル。
  トリガー条件:
  - 「Antigravity に聞いて」「Gemini の意見も」「Google のモデルで確認して」
  - 難しい設計判断・大きめのコンテキスト調査で別モデルの視点が欲しいとき
  - あるタスクを Antigravity に分業させたいとき（並列実装）
  - 「agy に投げて」「agy で実装して」
---

# ask-antigravity — Antigravity CLI に相談・委譲する

Claude 自身とは別の推論エンジン（Google / Gemini 系モデル）である Antigravity CLI (`agy`) を
呼び出し、セカンドオピニオンを得たり、独立した実装タスクを分業させたりするためのスキル。

## いつ使うか

- **セカンドオピニオン**: 設計・調査・大きめのコンテキストを要する判断を別モデルで裏取り。
- **分業/並列実装**: 自己完結したタスクを Antigravity に任せ、Claude は別作業や統合に集中。
- ユーザーが明示的に「Antigravity / Gemini に聞いて・実装させて」と言ったとき。

> Codex と両方に投げて突き合わせたいなら [ask-codex](../ask-codex/SKILL.md) を併用する。

## 前提

- 実行環境は DevContainer（コンテナ隔離でセキュリティを担保）。
- コマンドは `agy`。自律実行設定は `~/.gemini/antigravity-cli/settings.json`
  （`toolPermission: "always-proceed"`）。
- 認証: 初回は要サインイン。未認証だと `Please sign in ...` が返るので、その旨をユーザーに伝える
  （Claude が代理ログインはしない）。
- `GOOGLE_API_KEY` を `.env` に設定できる。

## 使い方

### 1. セカンドオピニオン（非対話・意見をもらう）

`-p`（`--print`）で単発プロンプトを非対話実行し、回答を stdout に得る。

```bash
agy -p "次の設計についてレビューして。懸念点と代替案を3つまで挙げて。<設計の要約や対象ファイルを具体的に記述>"
```

- 何を・どのファイルを・何の観点で見てほしいかを具体的に書く。
- 出力は**参考意見**として扱い、Claude が自分の見解と突き合わせて最終判断する。

### 2. 分業（実装を委譲する）

自己完結したタスクを任せる場合。ツール承認は `always-proceed` 設定で自動化されている。

```bash
agy --dangerously-skip-permissions -p "src/foo に <仕様> を実装して。既存の <規約> に合わせて。完了したら変更点を要約して。"
```

- **競合回避**: `agy` が触るファイル範囲を Claude が同時に編集しないこと。1タスク=1担当。
- 実行後は `git diff` で変更を確認し、Claude がレビューしてから統合する。
- 追加で参照させたいディレクトリは `--add-dir <dir>` で渡す。
- 長い処理は `--print-timeout <duration>` で待ち時間を延ばせる（既定 5分）。

## 出力の扱い（重要）

- `agy` の回答は**参考意見**。Claude が最終責任を持ち、必ず検証してから採用する。
- 相違があれば根拠を添えて自分の判断を明示し、要点を日本語で整理してユーザーに返す。

## トラブルシューティング

- `Please sign in` → 引数なしで `agy` を起動してサインインするようユーザーに案内。
  または `GOOGLE_API_KEY` を `.env` に設定。
- タイムアウト → `--print-timeout 10m` などで延長。
