#!/usr/bin/env bash
#
# notify.sh - タスク完了/入力待ちをローカル(ターミナル)と Slack に通知する
#
# Claude Code / Codex CLI のフック(notify)から呼ばれる。
#
# Usage: notify.sh <event> [noslack]
#   event:
#     stop  - タスク完了・入力待ち     … ベル + VS Code タブの進捗インジケータ(不定)
#     input - 質問/入力待ち            … ベル + タブのエラーインジケータ(赤・より目立つ)
#     clear - インジケータを消す        … (ユーザがメッセージ送信時など)
#   noslack: 第2引数に "noslack" を渡すと Slack 送信を抑止(codex exec 連発時のスパム防止)
#
# 通知チャネル:
#   1) ターミナル: BEL(\a) と OSC 9;4 進捗インジケータを、書き込める全 pty に送る。
#      OSC 9;4 は VS Code 統合ターミナルがネイティブ対応する「タブの進捗表示」で、
#      音設定に依存せず視覚的に気づける(要 VS Code。他端末では無害に無視される)。
#      音を鳴らすにはホスト VS Code の accessibility.signals.terminalBell を
#      { "sound": "on" } に(User 設定/JSON)。
#   2) Slack: 環境変数 SLACK_WEBHOOK_URL(Slack Incoming Webhook)が設定されていれば
#      メッセージを POST する。未設定なら何もしない(=完全オプトイン)。
#      env に無ければ $REPO_ROOT/.env からも読み取る。
#
set -u

event="${1:-stop}"
noslack="${2:-}"

# --- 1) ターミナル通知(全 pty へ) ---
term_write() {
  local seq="$1" p
  for p in /dev/pts/[0-9]*; do
    [ -w "$p" ] && printf '%b' "$seq" > "$p" 2>/dev/null
  done
}
case "$event" in
  stop)  term_write '\a\033]9;4;3;0\007'   ;;  # bell + 不定インジケータ(待機中の印)
  input) term_write '\a\033]9;4;2;100\007' ;;  # bell + エラー状態(赤・入力待ち)
  clear) term_write '\033]9;4;0;0\007'     ;;  # インジケータ解除
  *)     exit 0 ;;
esac

# --- 2) Slack 通知(オプトイン) ---
[ "$event" = "clear" ] && exit 0
[ "$noslack" = "noslack" ] && exit 0

# SLACK_WEBHOOK_URL: 環境変数優先。無ければ $REPO_ROOT/.env から抽出(source せず安全に)。
url="${SLACK_WEBHOOK_URL:-}"
if [ -z "$url" ] && [ -n "${REPO_ROOT:-}" ] && [ -f "${REPO_ROOT}/.env" ]; then
  url="$(grep -E '^[[:space:]]*SLACK_WEBHOOK_URL=' "${REPO_ROOT}/.env" 2>/dev/null \
        | tail -1 | cut -d= -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/")"
fi
[ -z "$url" ] && exit 0   # 未設定なら Slack はスキップ

case "$event" in
  stop)  text="✅ タスク完了・入力待ちです" ;;
  input) text="🔔 質問/入力待ちです" ;;
  *)     exit 0 ;;
esac
proj="$(basename "${REPO_ROOT:-$PWD}")"

curl -sf -m 5 -X POST -H 'Content-type: application/json' \
  --data "$(printf '{"text":"Claude Code [%s]: %s"}' "$proj" "$text")" \
  "$url" >/dev/null 2>&1 || true

exit 0
