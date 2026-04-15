#!/usr/bin/env zsh
# tmux-wt-new.sh - Streamlined worktree creation from the current session's bare repo
# Bound to C-Space C-w.
# Prompts for a branch name, branches off latest main, creates the worktree, runs
# `bn build`, and opens a new tmux window for it.

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init

session=$($TMUX_CMD display-message -p '#S' 2>/dev/null)
bare_repo="$BARE_DIR/${session}.git"

if [[ ! -d "$bare_repo" ]]; then
    echo "Session '$session' is not linked to a bare repo at $bare_repo"
    read -sk1 "?Press any key..."
    exit 1
fi

echo "Repo: $session"
echo "Fetching origin..."
git --git-dir="$bare_repo" fetch origin || {
    echo "Fetch failed"
    read -sk1 "?Press any key..."
    exit 1
}

git --git-dir="$bare_repo" branch -f main origin/main 2>/dev/null

printf "Branch name: "
read -r branch_name
[[ -z "$branch_name" ]] && exit 0

sanitized=$(echo "$branch_name" | tr '/' '-')
worktree_path="$WORKTREE_DIR/${session}/${sanitized}"

if [[ -d "$worktree_path" ]]; then
    echo "Worktree already exists: $worktree_path"
    read -sk1 "?Press any key..."
    exit 0
fi

echo "Creating worktree: $worktree_path"
mkdir -p "$WORKTREE_DIR/${session}"
if ! git --git-dir="$bare_repo" worktree add -b "$branch_name" "$worktree_path" main; then
    echo "Failed to create worktree"
    read -sk1 "?Press any key..."
    exit 1
fi

(cd "$worktree_path" && "$HOME/.bin/bn" build 2>/dev/null) || true

window_name="$sanitized"
if $TMUX_CMD list-windows -F '#{window_name}' | grep -qxF "$window_name"; then
    $TMUX_CMD select-window -t "$window_name"
else
    $TMUX_CMD new-window -n "$window_name" -c "$worktree_path"
fi
