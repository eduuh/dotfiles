#!/usr/bin/env zsh
# tmux-wt-kill.sh - Remove current window's worktree and kill the window.
# Bound to C-Space X. Run inside a tmux window whose cwd is under $WORKTREE_DIR.

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init

pane_path=$($TMUX_CMD display-message -p '#{pane_current_path}')

if [[ "$pane_path" != "$WORKTREE_DIR"/* ]]; then
    echo "Not a worktree path: $pane_path"
    read -sk1 "?Press any key..."
    exit 1
fi

rel="${pane_path#$WORKTREE_DIR/}"
repo="${rel%%/*}"
branch="${rel#*/}"
branch="${branch%%/*}"

if [[ "$branch" == "main" || "$branch" == "master" ]]; then
    echo "Refusing to remove the $branch worktree for $repo"
    read -sk1 "?Press any key..."
    exit 1
fi

worktree_path="$WORKTREE_DIR/$repo/$branch"
bare_repo="$BARE_DIR/${repo}.git"

if [[ ! -d "$bare_repo" ]]; then
    echo "Bare repo not found: $bare_repo"
    read -sk1 "?Press any key..."
    exit 1
fi

echo "Repo:   $repo"
echo "Branch: $branch"
echo "Path:   $worktree_path"
printf "\nRemove worktree and kill window? [y/N] "
read -r answer
[[ "$answer" != "y" && "$answer" != "Y" ]] && exit 0

window_id=$($TMUX_CMD display-message -p '#{window_id}')

if ! git --git-dir="$bare_repo" worktree remove "$worktree_path" 2>&1; then
    printf "\nRemove failed (dirty tree?). Force remove? [y/N] "
    read -r force
    if [[ "$force" == "y" || "$force" == "Y" ]]; then
        git --git-dir="$bare_repo" worktree remove --force "$worktree_path" || {
            echo "Still failed. Aborting."
            read -sk1 "?Press any key..."
            exit 1
        }
    else
        exit 1
    fi
fi

# Clean empty repo directory if no more branches
rmdir "$WORKTREE_DIR/$repo" 2>/dev/null || true

# Prune orphaned branch notes
"$HOME/.bin/bn" prune 2>/dev/null || true

# Kill the window (closes all panes)
$TMUX_CMD kill-window -t "$window_id"
