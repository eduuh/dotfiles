#!/usr/bin/env zsh
# tmux-wt-window.sh - Open a worktree as a tmux window in the current session
# Bound to prefix+o in tmux

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init
require_fzf

# Gather all worktrees (repo/branch)
worktrees=()
for repo_dir in "$WORKTREE_DIR"/*(N/); do
    local repo_name=$(basename "$repo_dir")
    for branch_dir in "$repo_dir"/*(N/); do
        [[ -d "$branch_dir" ]] || continue
        local branch_name=$(basename "$branch_dir")
        worktrees+=("${repo_name}/${branch_name}")
    done
done

[[ ${#worktrees[@]} -eq 0 ]] && { echo "No worktrees found"; exit 0; }

# fzf picker
selected=$(printf '%s\n' "${worktrees[@]}" | $FZF_CMD --prompt="Open as window: " --reverse)
[[ -z "$selected" ]] && exit 0

worktree_path="$WORKTREE_DIR/$selected"
window_name="$selected"

# If a window with this name already exists, switch to it
if $TMUX_CMD list-windows -F '#{window_name}' | grep -qxF "$window_name"; then
    $TMUX_CMD select-window -t "$window_name"
else
    $TMUX_CMD new-window -n "$window_name" -c "$worktree_path"
fi
