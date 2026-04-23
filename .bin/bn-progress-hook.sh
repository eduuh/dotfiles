#!/usr/bin/env zsh
# Claude Code SessionEnd hook: write a one-line session summary into the
# branch note's Progress section via `bn log-progress`.
#
# Input: JSON on stdin (fields: session_id, transcript_path, cwd).
# Silent if cwd is not inside a git worktree or no tool activity happened.

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

[[ -z "$CWD" ]] && exit 0
git -C "$CWD" rev-parse --show-toplevel >/dev/null 2>&1 || exit 0

FILES=0
BASH=0
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
    TOOLS=$(jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "tool_use") | .name // empty' "$TRANSCRIPT" 2>/dev/null)
    FILES=$(echo "$TOOLS" | grep -cE '^(Edit|Write|NotebookEdit)$' || echo 0)
    BASH=$(echo "$TOOLS"  | grep -c '^Bash$' || echo 0)
fi

parts=()
(( FILES > 0 )) && parts+=("${FILES} edits")
(( BASH  > 0 )) && parts+=("${BASH} bash cmds")

(( ${#parts[@]} == 0 )) && exit 0

summary="claude session: ${(j:, :)parts}"
(cd "$CWD" && "$HOME/.bin/bn" log-progress "$summary") 2>/dev/null || true
