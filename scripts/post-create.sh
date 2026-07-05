#!/usr/bin/env bash
#
# post-create.sh - DevContainer postCreate provisioning
#
# Runs once after the container is created (see .devcontainer/devcontainer.json).
# Kept as a script so the steps stay readable instead of a single giant
# one-liner. Steps:
#   - install Node dependencies
#   - install the git pre-commit hook
#   - deploy AI CLI configs (Claude / Codex / Antigravity / tmux / uv)
#   - install Claude Code plugins from their marketplaces
#   - run the container smoke test (verify.sh)
set -euo pipefail

# postCreate runs from the workspace subfolder; move to the repo root so the
# relative paths below (scripts/, .devcontainer/) resolve.
cd "${REPO_ROOT:-/workspaces/ai-agents-sandbox}"

# --- Node dependencies -------------------------------------------------------
npm install

# --- Git hooks ---------------------------------------------------------------
cp scripts/global-pre-commit ~/.config/git/hooks/pre-commit
chmod +x ~/.config/git/hooks/pre-commit
git config --global core.hooksPath ~/.config/git/hooks

# --- Claude Code config & plugins -------------------------------------------
chmod -R u+w ~/.claude ~/.codex ~/.gemini 2>/dev/null || true
cp .devcontainer/claude-settings.json ~/.claude/settings.json

# ~/.claude is a persisted volume, so a marketplace clone can be stale and make
# `plugin install` fail with "not found". Refresh first; a missing clone is fine
# because install re-fetches it. Plugin failures must not abort provisioning.
install_claude_plugins() {
  claude plugin marketplace update dev-workflow-marketplace 2>/dev/null || true
  claude plugin marketplace update cosense-cli 2>/dev/null || true
  claude plugin install dev-workflow-skills@dev-workflow-marketplace --scope user
  claude plugin install dev-security-skills@dev-workflow-marketplace --scope user
  claude plugin install cosense-cli@cosense-cli --scope user
}
install_claude_plugins || true

# --- Codex config ------------------------------------------------------------
cp .devcontainer/codex-config.toml ~/.codex/config.toml

# --- Antigravity config ------------------------------------------------------
mkdir -p ~/.gemini/antigravity-cli
cp .devcontainer/antigravity-settings.json ~/.gemini/antigravity-cli/settings.json

# --- tmux --------------------------------------------------------------------
cp .devcontainer/.tmux.conf ~/.tmux.conf

# --- uv ----------------------------------------------------------------------
mkdir -p ~/.config/uv
cp .devcontainer/uv.toml ~/.config/uv/uv.toml

# --- Smoke test --------------------------------------------------------------
bash scripts/verify.sh
