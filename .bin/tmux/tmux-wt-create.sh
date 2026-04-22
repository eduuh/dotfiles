#!/usr/bin/env zsh
# tmux-wt-create.sh - Create a worktree from latest main and open as a tmux window.
# Usage: tmux-wt-create.sh <branch-name>
#   e.g. tmux-wt-create.sh feat/my-feature

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init

branch_name="$1"
if [[ -z "$branch_name" ]]; then
    echo "Usage: tmux-wt-create.sh <branch-name>"
    exit 1
fi

session=$($TMUX_CMD display-message -p '#S' 2>/dev/null)
bare_repo="$BARE_DIR/${session}.git"

if [[ ! -d "$bare_repo" ]]; then
    echo "Session '$session' is not backed by a bare repo at $bare_repo"
    exit 1
fi

slug=$(echo "$branch_name" | tr '/' '-')
worktree_path="$WORKTREE_DIR/${session}/${slug}"

if ! ensure_main_worktree "$session"; then
    exit 1
fi

if ! ensure_worktree "$session" "$branch_name"; then
    exit 1
fi

echo "Opening window '$slug'..."
if $TMUX_CMD list-windows -F '#{window_name}' | grep -qxF "$slug"; then
    $TMUX_CMD select-window -t "$slug"
else
    $TMUX_CMD new-window -n "$slug" -c "$worktree_path"
fi

echo "Done: $worktree_path (branch: $branch_name)"
