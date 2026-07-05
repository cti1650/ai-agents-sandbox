# .claude — Claude Code から外部 AI CLI を呼ぶための設定

このディレクトリは、Claude Code が **Codex CLI (`codex`)** と **Antigravity CLI (`agy`)** を
適切なタイミングで **Skill / SubAgent** として呼び出すための設定一式です。
リポジトリルート（git ルート）に置いているため、コンテナを開けば自動で認識されます
（作業ディレクトリの `workspace/` は gitignore 対象なので、追跡・共有される root 側に配置）。

## 構成

```
.claude/
├── settings.json                    # codex/agy 実行を allow（bypass 外でもプロンプト削減）
├── skills/
│   ├── ask-codex/SKILL.md           # Codex に相談・実装委譲（セカンドオピニオン / 分業）
│   ├── ask-antigravity/SKILL.md     # Antigravity に相談・実装委譲
│   └── external-review/SKILL.md     # 現在の diff を Codex/agy にもレビューさせて突き合わせ
└── agents/
    ├── codex-cli.md                 # Codex へサブタスクを委譲するサブエージェント
    └── antigravity-cli.md           # Antigravity へサブタスクを委譲するサブエージェント
```

## 使い分け

| したいこと | 呼び出し方 |
|---|---|
| 別モデルに意見を聞く（セカンドオピニオン） | 「Codex に聞いて」「Gemini の意見も」→ `ask-codex` / `ask-antigravity` |
| 現在の変更を多重レビュー | 「外部レビューして」→ `external-review`（Claude の `/code-review` を補完） |
| 自己完結タスクを分業/並列実装 | 「この実装を Codex に任せて」→ `codex-cli` / `antigravity-cli` サブエージェント |

- **Skill** = 意図トリガーで発動する明示的な呼び出し口。挙動が予測しやすい。
- **SubAgent** = 独立コンテキストで自己完結タスクを丸ごと委譲。並列/分業向き。

## 前提

- 実行は DevContainer 内（コンテナ隔離でセキュリティ担保）。
- Codex は `~/.codex/config.toml`（`approval_policy=never`）、Antigravity は
  `~/.gemini/antigravity-cli/settings.json`（`always-proceed`）で承認自動化済み。
- **認証**: Codex=`OPENAI_API_KEY` or `codex login` / Antigravity=初回サインイン or
  `GOOGLE_API_KEY`。未認証時は各 CLI がサインインを促すので、その旨をユーザーに案内する
  （Claude が代理ログインはしない）。
- 外部 CLI の出力は**参考意見**。最終的な採否は Claude が検証して判断する。
