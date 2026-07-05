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

# Hardening check: passwordless root via sudo must NOT be available. The image
# grants no NOPASSWD sudoers entry, and no-new-privileges blocks setuid sudo
# from escalating anyway. If passwordless sudo *does* resolve, the container is
# running without the expected hardening (e.g. no-new-privileges was dropped).
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  yellow "  [WARN] passwordless sudo resolves — root escalation available (hardening weakened)"
else
  green "  [OK]   no passwordless root escalation via sudo"
fi

echo
echo "-- Python (info) --"
# 'python' is provided by the python-is-python3 package (rebuild image if missing).
if command -v python >/dev/null 2>&1; then
  green "  [OK]   python -> $(python --version 2>&1)"
else
  yellow "  [WARN] 'python' not found (install python-is-python3 / rebuild image)"
fi
# Expected system Python minor series; surfaces drift from the pinned base image.
py_ver=$(python3 -c 'import sys;print("%d.%d"%sys.version_info[:2])' 2>/dev/null)
if [ "$py_ver" = "3.11" ]; then
  green "  [OK]   python3 is 3.11.x ($(python3 --version 2>&1 | awk '{print $2}'))"
else
  yellow "  [WARN] python3 is ${py_ver:-unknown} (expected 3.11.x from the pinned base image)"
fi
# pip should route through the Takumi Guard PyPI proxy (blocking + 3-day quarantine).
# Use `config list`, not `config get`: `pip config get` ignores the PIP_CONFIG_FILE
# (`:env:`) scope this repo relies on, so it would report <default> even when routing
# is active. `config list`/`debug` do include that scope.
pip_index=$(python3 -m pip config list 2>/dev/null | sed -n "s/^global\.index-url='\(.*\)'$/\1/p")
if printf '%s' "$pip_index" | grep -q 'pypi.flatt.tech'; then
  green "  [OK]   pip index routed through Takumi Guard ($pip_index)"
else
  yellow "  [WARN] pip index is not Takumi Guard (got: ${pip_index:-<default>}); check PIP_CONFIG_FILE"
fi
# uv does not read PIP_CONFIG_FILE; it is routed via the global ~/.config/uv/uv.toml.
if command -v uv >/dev/null 2>&1; then
  green "  [OK]   uv available ($(uv --version 2>/dev/null))"
  if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/uv/uv.toml" ] && grep -q 'pypi.flatt.tech' "${XDG_CONFIG_HOME:-$HOME/.config}/uv/uv.toml" 2>/dev/null; then
    green "  [OK]   uv index routed through Takumi Guard (~/.config/uv/uv.toml)"
  else
    yellow "  [WARN] uv index is not Takumi Guard; check ~/.config/uv/uv.toml (copied by postCreateCommand)"
  fi
else
  yellow "  [WARN] uv not installed (rebuild image)"
fi

echo
echo "-- Secret scanners (info) --"
# secretlint and gitleaks for layered secret detection
if [ -f node_modules/.bin/secretlint ] || command -v secretlint >/dev/null 2>&1; then
  green "  [OK]   secretlint available"
else
  yellow "  [WARN] secretlint not installed (run 'npm install')"
fi
if command -v gitleaks >/dev/null 2>&1; then
  green "  [OK]   gitleaks available ($(gitleaks version 2>/dev/null || echo 'unknown'))"
else
  yellow "  [WARN] gitleaks not installed"
fi

echo
echo "-- Pre-commit hooks (info) --"
# lefthook installs a pre-commit hook that runs secretlint on staged files.
if grep -q 'lefthook' .git/hooks/pre-commit 2>/dev/null; then
  green "  [OK]   lefthook pre-commit hook installed"
else
  yellow "  [WARN] pre-commit hook not installed (run 'npm install' or 'npx lefthook install')"
fi
# Global git hooks for workspace repos
if [ -f "$HOME/.config/git/hooks/pre-commit" ]; then
  green "  [OK]   global pre-commit hook installed"
else
  yellow "  [WARN] global pre-commit hook not found"
fi

echo
echo "-- SSH config compatibility (info) --"
# Host ~/.ssh/config is bind-mounted read-only. macOS-only options such as
# 'UseKeychain' are rejected by Linux OpenSSH and break git over SSH.
if ! command -v ssh >/dev/null 2>&1; then
  yellow "  [WARN] ssh client not found (skipping)"
elif [ ! -f "$HOME/.ssh/config" ]; then
  green "  [OK]   no ~/.ssh/config (nothing to validate)"
elif ssh_err=$(ssh -G github.com 2>&1 >/dev/null); then
  green "  [OK]   ~/.ssh/config parses cleanly"
else
  yellow "  [WARN] ~/.ssh/config has options unsupported on Linux:"
  printf '%s\n' "$ssh_err" | sed 's/^/           /'
  yellow "         Fix on the host config: add under 'Host *':  IgnoreUnknown UseKeychain"
fi

echo
if [ "$fail" -eq 0 ]; then
  green "== Verification PASSED =="
else
  red   "== Verification FAILED (see [FAIL] lines above) =="
fi
exit "$fail"
