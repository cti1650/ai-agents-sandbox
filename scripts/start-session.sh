#!/bin/bash
#
# start-session.sh - Start AI agent tmux session
#
# Usage:
#   ./scripts/start-session.sh [session-name] [task-description]
#
# Examples:
#   ./scripts/start-session.sh                    # Start default session
#   ./scripts/start-session.sh feature-auth       # Named session
#   ./scripts/start-session.sh bugfix "Fix login" # With task description
#

set -euo pipefail

SESSION_NAME="${1:-ai-agent}"
TASK_DESC="${2:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== AI Agents Sandbox - tmux Session ===${NC}"
echo

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo -e "${YELLOW}Warning: tmux is not installed${NC}"
    echo "Running Claude Code directly without tmux..."
    echo
    if [ -n "$TASK_DESC" ]; then
        claude "$TASK_DESC"
    else
        claude
    fi
    exit 0
fi

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "${YELLOW}Session '$SESSION_NAME' already exists${NC}"
    echo
    echo "Options:"
    echo "  1) Attach to existing session:  tmux attach -t $SESSION_NAME"
    echo "  2) Kill and recreate:           tmux kill-session -t $SESSION_NAME"
    echo
    read -p "Attach to existing session? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        tmux attach -t "$SESSION_NAME"
        exit 0
    else
        tmux kill-session -t "$SESSION_NAME"
    fi
fi

# Create new tmux session
echo -e "${GREEN}Creating tmux session: $SESSION_NAME${NC}"

if [ -n "$TASK_DESC" ]; then
    # Start with Claude and task description
    tmux new-session -d -s "$SESSION_NAME" "claude \"$TASK_DESC\"; exec bash"
else
    # Start with Claude interactively
    tmux new-session -d -s "$SESSION_NAME" "claude; exec bash"
fi

# Attach to session
echo -e "${GREEN}Session created. Attaching...${NC}"
echo
echo -e "${YELLOW}Tip: Detach with Ctrl+b, then d${NC}"
echo -e "${YELLOW}     Reattach with: tmux attach -t $SESSION_NAME${NC}"
echo

sleep 0.5
tmux attach -t "$SESSION_NAME"
