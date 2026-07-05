---
name: external-review
description: |
  現在の変更（diff）を外部 AI CLI（Codex / Antigravity）にコードレビューさせ、
  Claude のレビューと突き合わせて統合するスキル。
  トリガー条件:
  - 「外部レビューして」「Codex/Gemini にもレビューさせて」
  - 「この変更を別のモデルでもチェックして」
  - PR 作成前のセルフレビューを厚くしたいとき
  - 「external-review」「クロスレビュー」
---

# external-review — 外部 CLI による多重コードレビュー

Claude 単独のレビューに加え、別モデル（Codex / Antigravity）にも同じ変更をレビューさせ、
指摘を突き合わせて「確度の高い指摘」に絞り込むためのスキル。PR 前のセルフレビューを厚くする。

## いつ使うか

- ユーザーが「外部レビュー」「Codex/Gemini でもレビュー」と言ったとき。
- 影響が大きい変更を出す前に、単一モデルの見落としを減らしたいとき。

> Claude 自身の diff レビューは `/code-review` を使う。このスキルはそれを**補完**する。

## 手順

### 1. まず対象の変更を把握する

```bash
git status && git diff --stat
```

未コミットの変更をレビュー対象にする。ブランチ比較なら base を控えておく。

### 2. Codex にレビューさせる

Codex には専用のレビューサブコマンドがある。

```bash
# 未コミット（staged / unstaged / untracked）を対象
codex exec review --uncommitted "セキュリティ・境界条件・エラーハンドリングを重点的に。"

# base ブランチとの差分を対象
codex exec review --base main "リグレッションと後方互換性の観点で。"
```

### 3. Antigravity にレビューさせる

`agy` にはレビュー専用サブコマンドが無いため、diff を渡して依頼する。

```bash
git diff | agy -p "以下は現在の作業ツリーの差分。バグ・設計・可読性の観点でレビューし、重要度順に指摘して。$(cat)"
```

> 上の `$(cat)` はパイプ内容を渡すための例。うまく渡らない場合は差分を一時ファイルに保存し、
> `agy --add-dir <dir> -p "<path> の diff をレビューして"` のようにファイル参照させる。

### 4. 突き合わせて統合（Claude の仕事）

- 各 CLI の指摘 + Claude 自身のレビューを集約する。
- **複数モデルが一致した指摘**＝確度が高い → 優先して対応。
- 1モデルだけの指摘は Claude が妥当性を検証し、採否と理由を明示する。
- 出力は「重要度 / 指摘 / 出どころ（Claude・Codex・agy）/ 推奨対応」を表にして日本語で提示。

## 前提・注意

- コンテナ内なので承認プロンプトなしで実行される（`codex` は `approval_policy=never`）。
- 認証未設定なら各 CLI がサインインを促す。その場合はユーザーに案内する。
- 外部 CLI の指摘は**参考**。最終的な採否は Claude が検証して決める。
