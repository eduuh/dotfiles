#!/usr/bin/env zsh
# tmux-wt.sh - Unified "go to or create worktree" for the current session's bare repo.
# Bound to C-Space o.
#
# Flow:
#   1. Session name must match a bare repo in $BARE_DIR/<session>.git
#   2. fzf lists existing worktree branches for that repo
#   3. Select one → open it as a window
#   4. Type a name that doesn't match → create fresh worktree from latest main,
#      then open it as a window

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init
require_fzf

force_new=0
[[ "$1" == "--new" ]] && force_new=1

session=$($TMUX_CMD display-message -p '#S' 2>/dev/null)
bare_repo="$BARE_DIR/${session}.git"

# Non-bare repo (plain clone): treat the repo itself as the single "main" worktree.
# Just open or select a "main" window at $PROJECT_ROOT/<session> and exit.
if [[ ! -d "$bare_repo" ]]; then
    repo_path="$PROJECT_ROOT/$session"
    if [[ ! -d "$repo_path" ]]; then
        echo "No repo found at $repo_path"
        read -sk1 "?Press any key..."
        exit 1
    fi
    window_name="main"
    if (( force_new )); then
        open_worktree_window "" "$window_name" "$repo_path"
    elif $TMUX_CMD list-windows -F '#{window_name}' | grep -qxF "$window_name"; then
        $TMUX_CMD select-window -t "$window_name"
    else
        open_worktree_window "" "$window_name" "$repo_path"
    fi
    exit 0
fi

# Guarantee main worktree exists before any open/create operation
if ! ensure_main_worktree "$session"; then
    read -sk1 "?Press any key..."
    exit 1
fi

# Gather existing worktree branches for this repo
branches=()
if [[ -d "$WORKTREE_DIR/$session" ]]; then
    for dir in "$WORKTREE_DIR/$session"/*(N/); do
        branches+=("$(basename "$dir")")
    done
fi

# fzf picker with --print-query so a typed name that doesn't match still comes through
result=$(printf '%s\n' "${branches[@]}" | $FZF_CMD \
    --prompt="Worktree: " \
    --reverse \
    --print-query \
    --header="Enter = open; type new name + Enter = create from main")
fzf_exit=$?

# User cancelled (Esc / Ctrl-C)
[[ $fzf_exit -eq 130 ]] && exit 0

query=$(echo "$result" | sed -n '1p')
selection=$(echo "$result" | sed -n '2p')

if [[ -n "$selection" ]]; then
    branch_name="$selection"
elif [[ -n "$query" ]]; then
    branch_name="$query"
else
    exit 0
fi

sanitized="${branch_name//\//-}"
worktree_path="$WORKTREE_DIR/$session/$sanitized"

if ! ensure_worktree "$session" "$branch_name"; then
    read -sk1 "?Press any key..."
    exit 1
fi

# Open/switch to window for this worktree
window_name="$sanitized"
if (( force_new )); then
    open_worktree_window "" "$window_name" "$worktree_path"
elif $TMUX_CMD list-windows -F '#{window_name}' | grep -qxF "$window_name"; then
    $TMUX_CMD select-window -t "$window_name"
else
    open_worktree_window "" "$window_name" "$worktree_path"
fi
