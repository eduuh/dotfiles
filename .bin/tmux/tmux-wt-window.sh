#!/usr/bin/env zsh
# tmux-wt-window.sh - Open a worktree as a tmux window in the current session
# Bound to prefix+o in tmux

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init
require_fzf

# Detect current repo from session name (scope to this repo's worktrees)
current_session=$($TMUX_CMD display-message -p '#S')
current_repo=""
if is_bare_repo "$current_session"; then
    current_repo="$current_session"
fi

# Gather worktrees (filtered to current repo if detected)
worktrees=()
for repo_dir in "$WORKTREE_DIR"/*(N/); do
    local repo_name=$(basename "$repo_dir")
    [[ -n "$current_repo" && "$repo_name" != "$current_repo" ]] && continue
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
# Use branch name only as window name (not repo/branch)
window_name="${selected#*/}"

# If a window with this name already exists, switch to it
if $TMUX_CMD list-windows -F '#{window_name}' | grep -qxF "$window_name"; then
    $TMUX_CMD select-window -t "$window_name"
else
    $TMUX_CMD new-window -n "$window_name" -c "$worktree_path"
fi
