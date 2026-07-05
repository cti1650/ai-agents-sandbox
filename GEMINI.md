# GEMINI.md — Antigravity CLI (`agy`) 向けルール

プロジェクト共通の作法は [AGENTS.md](AGENTS.md) に集約しています。まずそちらを読んでください。
（`agy` は `AGENTS.md` もネイティブに読み込みますが、明示的に取り込みます。）

@AGENTS.md

---

## Antigravity (`agy`) 固有メモ

- 実行は DevContainer 内。自律実行モード（`always-proceed`）で承認プロンプトなしに走るため、
  [AGENTS.md](AGENTS.md) の「禁止操作」を自分で厳守する。
- 認証は初回サインイン（OAuth）または `GOOGLE_API_KEY`。未認証時はサインインを促す表示に従う。
- Claude Code から呼ばれる場合（`agy -p` / `--print`）は、依頼されたサブタスクに集中し、
  変更点を最後に要約する。触るファイル範囲を広げすぎない。
