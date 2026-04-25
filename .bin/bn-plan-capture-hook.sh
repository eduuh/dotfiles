#!/usr/bin/env zsh
# Claude Code PostToolUse hook for ExitPlanMode.
# When a plan is approved, copy the most recent file from ~/.claude/plans/
# into the current branch note's plans/ subfolder. Silent no-op when:
#   - cwd isn't a git repo
#   - no plan files exist
#   - the plan response indicates rejection (where detectable)
#   - destination already exists (same plan approved twice)
#
# Input: JSON on stdin (fields: tool_name, tool_response, cwd).

set -euo pipefail

PLANS_DIR="$HOME/.claude/plans"

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[[ "$TOOL" != "ExitPlanMode" ]] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$CWD" ]] && exit 0
git -C "$CWD" rev-parse --show-toplevel >/dev/null 2>&1 || exit 0

# Approval detection: Claude Code surfaces an approval flag in tool_response.
# Best-effort — schema may vary. Skip capture only on an EXPLICIT false across
# any of the plausible field names. If the field is absent or unknown, lean
# toward capture (user can `bn plan rm` later).
# NB: using `//` here would mistreat `false` as falsy and default to "unknown",
# so compare to `false` directly.
REJECTED=$(echo "$INPUT" | jq -r '
    (.tool_response.approved == false)
    or (.tool_response.approval == false)
    or (.tool_response.plan_approved == false)
    or (.tool_response.user_approved == false)
')
[[ "$REJECTED" == "true" ]] && exit 0

# Find the most recent plan file
[[ ! -d "$PLANS_DIR" ]] && exit 0
latest=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
[[ -z "$latest" ]] && exit 0

# Resolve branch note dir (run bn from CWD so it uses the right repo context)
note_dir=$(cd "$CWD" && "$HOME/.bin/bn" --path 2>/dev/null) || exit 0
[[ -z "$note_dir" || ! -d "$note_dir" ]] && exit 0

slug=${latest:t:r}                     # basename sans .md
date=$(date +%Y-%m-%d)
dest="$note_dir/plans/${date}-${slug}.md"

mkdir -p "$note_dir/plans"
if [[ -f "$dest" ]]; then
    # Idempotent: same plan approved twice shouldn't duplicate
    exit 0
fi

cp "$latest" "$dest"
echo "[bn] captured plan: ${date}-${slug}" >&2
