#!/usr/bin/env bash
# tmux-sync-repos.sh - Open matching repos in synchronized vertical panes
# Usage: tmux-sync-repos.sh <prefix> [base_dir]
# When prefix matches a repo name in worktree/, opens all its branch worktrees as synced panes

source "$HOME/.bin/tmux-lib.sh"

require_tmux
tmux_init

PREFIX="$1"
WORKTREE_BASE="${2:-$HOME/projects/worktree}"

if [[ -z "$PREFIX" ]]; then
    echo "Usage: tmux-sync-repos.sh <prefix> [base_dir]"
    exit 1
fi

# Find matching repo directories in worktree/
matches=()
shopt -s nocaseglob nullglob
for repo_dir in "$WORKTREE_BASE"/"$PREFIX"*/; do
    [[ -d "$repo_dir" ]] || continue
    # Collect all branch worktrees within the matching repo
    for branch_dir in "$repo_dir"/*/; do
        [[ -d "$branch_dir" ]] && matches+=("${branch_dir%/}")
    done
done
shopt -u nocaseglob nullglob

if [[ ${#matches[@]} -eq 0 ]]; then
    $TMUX_CMD display-message "No worktrees matching '$PREFIX*' in $WORKTREE_BASE"
    exit 1
fi

if [[ ${#matches[@]} -eq 1 ]]; then
    $TMUX_CMD display-message "Only one match found: ${matches[0]##*/}"
    exit 1
fi

# Create new window with first directory
window_name="sync:$PREFIX"
$TMUX_CMD new-window -n "$window_name" -c "${matches[0]}"

# Split vertically for remaining directories
for dir in "${matches[@]:1}"; do
    $TMUX_CMD split-window -h -t ":$window_name" -c "$dir"
    $TMUX_CMD select-layout -t ":$window_name" even-horizontal
done

# Enable synchronized panes
$TMUX_CMD set-window-option -t ":$window_name" synchronize-panes on

# Display info
$TMUX_CMD display-message "Synced ${#matches[@]} worktrees: ${PREFIX}* (sync ON)"
