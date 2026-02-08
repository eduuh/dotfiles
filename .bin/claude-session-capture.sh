#!/usr/bin/env bash
# Claude Code session capture hook
# Usage: Receives JSON on stdin from Claude Code hooks
#   claude-session-capture.sh start   (SessionStart hook)
#   claude-session-capture.sh stop    (SessionEnd hook)

set -euo pipefail

TASKS_FILE="$HOME/projects/personal-notes/active-claude-tasks.md"
CACHE_DIR="$HOME/.cache/claude-sessions"
TODAY=$(date +%Y-%m-%d)
ACTION="${1:-start}"

mkdir -p "$CACHE_DIR"

# Read JSON from stdin (Claude Code passes hook context as JSON)
INPUT_JSON=$(cat)

# Extract fields from JSON
SESSION_ID=$(echo "$INPUT_JSON" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT_JSON" | jq -r '.transcript_path // empty')
CWD=$(echo "$INPUT_JSON" | jq -r '.cwd // empty')

# Fallbacks for directory/branch if JSON didn't provide them
DIR="${CWD:-$(pwd)}"
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null || echo "")
TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null || echo "")

# Infer project name from directory
PROJECT=$(basename "$(dirname "$DIR")" | sed 's/^1JS-//' | sed 's/-/ /g')

if [[ ! -f "$TASKS_FILE" ]]; then
  exit 0
fi

CONTENT=$(cat "$TASKS_FILE")

# Update date
CONTENT=$(echo "$CONTENT" | sed "s/^Updated:.*/Updated: $TODAY/")

case "$ACTION" in
  start)
    START_TIME=$(date +%s)
    START_DISPLAY=$(date +%H:%M)

    # Store start time for duration calculation
    if [[ -n "$SESSION_ID" ]]; then
      echo "$START_TIME" > "$CACHE_DIR/${SESSION_ID}.start"
    fi

    # Check if branch already has an In Progress entry
    if [[ -n "$BRANCH" ]] && echo "$CONTENT" | grep -q "Branch: \`$BRANCH\`"; then
      # Update existing entry's tmux, directory, and session info
      if [[ -n "$TMUX_SESSION" ]]; then
        CONTENT=$(echo "$CONTENT" | sed "/Branch: \`$BRANCH\`/{n;s/^- Tmux: .*/- Tmux: \`$TMUX_SESSION\`/;}")
      fi
      # Update session ID line if it exists, or add it after Directory line
      if [[ -n "$SESSION_ID" ]]; then
        if echo "$CONTENT" | grep -q "Branch: \`$BRANCH\`" && echo "$CONTENT" | grep -A5 "Branch: \`$BRANCH\`" | grep -q "^- Session:"; then
          CONTENT=$(echo "$CONTENT" | awk -v branch="$BRANCH" -v sid="$SESSION_ID" '
            /Branch: `/ && index($0, branch) { found=1 }
            found && /^- Session:/ { $0 = "- Session: `" sid "` | Resume: `claude --resume " sid "`"; found=0 }
            { print }
          ')
        fi
      fi
      # Update status
      CONTENT=$(echo "$CONTENT" | awk -v branch="$BRANCH" -v ts="$START_DISPLAY" '
        /Branch: `/ && index($0, branch) { found=1 }
        found && /^- Status:/ { $0 = "- Status: Starting session"; found=0 }
        { print }
      ')
    else
      # Build new entry
      ENTRY="**${PROJECT:-Session}**"
      ENTRY="$ENTRY\n- Project: 1JS Midgard | Branch: \`${BRANCH:-unknown}\`"
      [[ -n "$TMUX_SESSION" ]] && ENTRY="$ENTRY\n- Tmux: \`$TMUX_SESSION\`"
      ENTRY="$ENTRY\n- Directory: \`$DIR\`"
      [[ -n "$SESSION_ID" ]] && ENTRY="$ENTRY\n- Session: \`$SESSION_ID\` | Resume: \`claude --resume $SESSION_ID\`"
      ENTRY="$ENTRY\n- Started: $START_DISPLAY"
      ENTRY="$ENTRY\n- Status: Starting session"

      CONTENT=$(echo "$CONTENT" | sed "/^## 🟡 In Progress$/a\\
\\
$ENTRY")
    fi
    ;;

  stop)
    TIMESTAMP=$(date +"%H:%M")
    DURATION_STR=""
    SUMMARY_STR=""

    # Calculate duration from stored start time
    if [[ -n "$SESSION_ID" ]] && [[ -f "$CACHE_DIR/${SESSION_ID}.start" ]]; then
      START_TIME=$(cat "$CACHE_DIR/${SESSION_ID}.start")
      NOW=$(date +%s)
      ELAPSED=$((NOW - START_TIME))
      MINUTES=$((ELAPSED / 60))
      if (( MINUTES >= 60 )); then
        HOURS=$((MINUTES / 60))
        REMAINING_MINS=$((MINUTES % 60))
        DURATION_STR="${HOURS}h${REMAINING_MINS}m"
      else
        DURATION_STR="${MINUTES}m"
      fi
      rm -f "$CACHE_DIR/${SESSION_ID}.start"
    fi

    # Parse transcript for work summary
    # Transcript is JSONL where:
    #   - Tool uses are in assistant messages: .message.content[].type == "tool_use"
    #   - First user prompt: .type == "user" with .message.content as a string (not tool_result array)
    if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
      # Count tool uses from assistant message content blocks
      FILES_MODIFIED=$(jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "tool_use") | .name // empty' "$TRANSCRIPT_PATH" 2>/dev/null | grep -cE "^(Edit|Write|NotebookEdit)$" || echo "0")
      BASH_COMMANDS=$(jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "tool_use") | .name // empty' "$TRANSCRIPT_PATH" 2>/dev/null | grep -c "^Bash$" || echo "0")

      # Extract first user message as goal (the initial prompt has .message.content as a string)
      GOAL=$(jq -r 'select(.type == "user") | .message.content | if type == "string" then . else empty end' "$TRANSCRIPT_PATH" 2>/dev/null | head -1 | cut -c1-80)
      GOAL=$(echo "$GOAL" | tr '\n' ' ' | sed 's/  */ /g')

      PARTS=""
      [[ -n "$GOAL" ]] && PARTS="$GOAL"
      STATS=""
      (( FILES_MODIFIED > 0 )) && STATS="${FILES_MODIFIED} files modified"
      if (( BASH_COMMANDS > 0 )); then
        [[ -n "$STATS" ]] && STATS="$STATS, "
        STATS="${STATS}${BASH_COMMANDS} bash commands"
      fi
      if [[ -n "$PARTS" ]] && [[ -n "$STATS" ]]; then
        SUMMARY_STR="$PARTS ($STATS)"
      elif [[ -n "$STATS" ]]; then
        SUMMARY_STR="$STATS"
      elif [[ -n "$PARTS" ]]; then
        SUMMARY_STR="$PARTS"
      fi
    fi

    # Build the status line
    STATUS_LINE="- Status: Last active $TODAY $TIMESTAMP"
    [[ -n "$DURATION_STR" ]] && STATUS_LINE="- Duration: $DURATION_STR | $STATUS_LINE"

    # Update entry for this branch
    if [[ -n "$BRANCH" ]] && echo "$CONTENT" | grep -q "Branch: \`$BRANCH\`"; then
      # Update or add duration/summary line
      if [[ -n "$SUMMARY_STR" ]]; then
        # Check if Summary line exists
        if echo "$CONTENT" | grep -A8 "Branch: \`$BRANCH\`" | grep -q "^- Summary:"; then
          CONTENT=$(echo "$CONTENT" | awk -v branch="$BRANCH" -v summary="$SUMMARY_STR" '
            /Branch: `/ && index($0, branch) { found=1 }
            found && /^- Summary:/ { $0 = "- Summary: " summary; found=0 }
            { print }
          ')
        else
          # Add summary before Status line
          CONTENT=$(echo "$CONTENT" | awk -v branch="$BRANCH" -v summary="$SUMMARY_STR" '
            /Branch: `/ && index($0, branch) { found=1 }
            found && /^- Status:/ { print "- Summary: " summary; found=0 }
            { print }
          ')
        fi
      fi

      # Update or add duration
      if [[ -n "$DURATION_STR" ]]; then
        if echo "$CONTENT" | grep -A8 "Branch: \`$BRANCH\`" | grep -q "^- Duration:"; then
          CONTENT=$(echo "$CONTENT" | awk -v branch="$BRANCH" -v dur="$DURATION_STR" '
            /Branch: `/ && index($0, branch) { found=1 }
            found && /^- Duration:/ { $0 = "- Duration: " dur; found=0 }
            { print }
          ')
        else
          # Add duration before Status line
          CONTENT=$(echo "$CONTENT" | awk -v branch="$BRANCH" -v dur="$DURATION_STR" '
            /Branch: `/ && index($0, branch) { found=1 }
            found && /^- Status:/ { print "- Duration: " dur; found=0 }
            { print }
          ')
        fi
      fi

      # Update status line
      CONTENT=$(echo "$CONTENT" | awk -v branch="$BRANCH" -v ts="$TODAY $TIMESTAMP" '
        /Branch: `/ && index($0, branch) { found=1 }
        found && /^- Status:/ { $0 = "- Status: Last active " ts; found=0 }
        { print }
      ')
    fi
    ;;
esac

echo "$CONTENT" > "$TASKS_FILE"
