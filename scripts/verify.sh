#!/usr/bin/env bash
#
# verify.sh - DevContainer smoke test
#
# Confirms that the AI Agents Sandbox container was built correctly:
#   - AI CLIs and base tooling are installed
#   - the container runs as the expected non-root user
#   - the documented security hardening is in effect
#
# Hard checks (REQUIRED) fail the script with a non-zero exit code.
# Soft checks (INFO) only warn, because they depend on the runtime flags
# the container happens to be launched with (e.g. CI vs. local VS Code).
#
set -uo pipefail

fail=0

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

# Hard check: a command must exist on PATH.
require_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    green "  [OK]   $cmd ($(command -v "$cmd"))"
  else
    red   "  [FAIL] $cmd not found on PATH"
    fail=1
  fi
}

# Soft check: report a command's version if present, never fail.
report_version() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    local ver
    ver=$(timeout 20 "$cmd" --version 2>/dev/null | head -n1)
    green "  [OK]   $cmd --version: ${ver:-<no output>}"
  else
    yellow "  [WARN] $cmd not found (skipping version)"
  fi
}

echo "== AI Agents Sandbox :: container verification =="

echo
echo "-- AI CLIs (required) --"
require_cmd claude
require_cmd codex
require_cmd agy

echo
echo "-- AI CLI versions (info) --"
report_version claude
report_version codex
report_version agy

echo
echo "-- Base tooling (required) --"
for c in git gh jq curl python3 node npm; do
  require_cmd "$c"
done

echo
echo "-- User & permissions --"
current_user=$(id -un)
current_uid=$(id -u)
if [ "$current_uid" -ne 0 ]; then
  green "  [OK]   running as non-root: $current_user (uid=$current_uid)"
else
  red   "  [FAIL] running as root (expected non-root 'vscode')"
  fail=1
fi

if [ "$current_user" = "vscode" ]; then
  green "  [OK]   user is 'vscode'"
else
  yellow "  [WARN] user is '$current_user' (expected 'vscode')"
fi

if [ -w "${PWD}" ]; then
  green "  [OK]   workspace is writable: ${PWD}"
else
  red   "  [FAIL] workspace is not writable: ${PWD}"
  fail=1
fi

echo
echo "-- Security hardening (info) --"
# no-new-privileges: NoNewPrivs bit in /proc/self/status should be 1
if grep -qE '^NoNewPrivs:\s*1' /proc/self/status 2>/dev/null; then
  green "  [OK]   no-new-privileges is active"
else
  yellow "  [WARN] no-new-privileges not detected (NoNewPrivs != 1)"
fi

# Dropped capabilities: effective capability set should be minimal.
cap_eff=$(grep -E '^CapEff:' /proc/self/status 2>/dev/null | awk '{print $2}')
if [ -n "${cap_eff:-}" ]; then
  if [ "$cap_eff" = "0000000000000000" ]; then
    green "  [OK]   effective capabilities fully dropped (CapEff=$cap_eff)"
  else
    yellow "  [WARN] effective capabilities present (CapEff=$cap_eff)"
  fi
fi

# sudo is configured NOPASSWD for vscode; verify it resolves.
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  green "  [OK]   passwordless sudo works"
else
  yellow "  [WARN] passwordless sudo not available"
fi

echo
if [ "$fail" -eq 0 ]; then
  green "== Verification PASSED =="
else
  red   "== Verification FAILED (see [FAIL] lines above) =="
fi
exit "$fail"
