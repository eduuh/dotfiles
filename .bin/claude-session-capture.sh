#!/usr/bin/env bash
# Claude Code session capture hook
# Usage: claude-session-capture.sh [start|stop]

set -euo pipefail

TASKS_FILE="$HOME/projects/personal-notes/active-claude-tasks.md"
TODAY=$(date +%Y-%m-%d)

# Gather session info
TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null || echo "")
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
DIR=$(pwd)

# Infer project name from directory
PROJECT=$(basename "$(dirname "$DIR")" | sed 's/^1JS-//' | sed 's/-/ /g')

if [[ ! -f "$TASKS_FILE" ]]; then
  exit 0
fi

CONTENT=$(cat "$TASKS_FILE")

# Update date
CONTENT=$(echo "$CONTENT" | sed "s/^Updated:.*/Updated: $TODAY/")

ACTION="${1:-start}"

case "$ACTION" in
  start)
    # Check if branch already has an In Progress entry
    if [[ -n "$BRANCH" ]] && echo "$CONTENT" | grep -q "Branch: \`$BRANCH\`"; then
      # Update existing entry's tmux and directory
      if [[ -n "$TMUX_SESSION" ]]; then
        CONTENT=$(echo "$CONTENT" | sed "/Branch: \`$BRANCH\`/{n;s/^- Tmux: .*/- Tmux: \`$TMUX_SESSION\`/;}")
      fi
    else
      # Add new In Progress entry after the section header
      ENTRY="**${PROJECT:-Session}**\n- Project: 1JS Midgard | Branch: \`${BRANCH:-unknown}\`"
      [[ -n "$TMUX_SESSION" ]] && ENTRY="$ENTRY\n- Tmux: \`$TMUX_SESSION\`"
      ENTRY="$ENTRY\n- Directory: \`$DIR\`\n- Status: Starting session"

      CONTENT=$(echo "$CONTENT" | sed "/^## 🟡 In Progress$/a\\
\\
$ENTRY")
    fi
    ;;

  stop)
    # Update status line for this branch's entry to show last active time
    if [[ -n "$BRANCH" ]] && echo "$CONTENT" | grep -q "Branch: \`$BRANCH\`"; then
      TIMESTAMP=$(date +%H:%M)
      CONTENT=$(echo "$CONTENT" | awk -v branch="$BRANCH" -v ts="$TODAY $TIMESTAMP" '
        /Branch: `/ && index($0, branch) { found=1 }
        found && /^- Status:/ { $0 = "- Status: Last active " ts; found=0 }
        { print }
      ')
    fi
    ;;
esac

echo "$CONTENT" > "$TASKS_FILE"
