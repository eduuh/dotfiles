#!/usr/bin/env zsh
# tmux-wt-kill.sh - Remove a worktree and kill its tmux window.
#
# Default (bound to prefix X): operate on the current window. The window's
# pane_current_path must be under $WORKTREE_DIR.
#
# --pick (bound to prefix D): fzf-pick any worktree in the current session's
# bare repo (main/master filtered out), confirm, then kill its window (if
# open) and delete the worktree.

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init

mode="current"
[[ "$1" == "--pick" ]] && mode="pick"

# remove_worktree <repo> <branch> [window_id]
# Prompts for confirmation, removes the worktree (with optional --force on
# failure), kills the window if provided, and prunes orphan branch notes.
remove_worktree() {
    local repo="$1" branch="$2" window_id="$3"
    local worktree_path="$WORKTREE_DIR/$repo/$branch"
    local bare_repo="$BARE_DIR/${repo}.git"

    if [[ ! -d "$bare_repo" ]]; then
        echo "Bare repo not found: $bare_repo"
        read -sk1 "?Press any key..."
        return 1
    fi

    echo "Repo:   $repo"
    echo "Branch: $branch"
    echo "Path:   $worktree_path"
    printf "\nRemove worktree and kill window? [y/N] "
    read -r answer
    [[ "$answer" != "y" && "$answer" != "Y" ]] && return 0

    if ! git --git-dir="$bare_repo" worktree remove "$worktree_path" 2>&1; then
        printf "\nRemove failed (dirty tree?). Force remove? [y/N] "
        read -r force
        if [[ "$force" == "y" || "$force" == "Y" ]]; then
            git --git-dir="$bare_repo" worktree remove --force "$worktree_path" || {
                echo "Still failed. Aborting."
                read -sk1 "?Press any key..."
                return 1
            }
        else
            return 1
        fi
    fi

    rmdir "$WORKTREE_DIR/$repo" 2>/dev/null || true
    "$HOME/.bin/bn" prune 2>/dev/null || true

    local nvim_hash
    nvim_hash=$(printf '%s' "$worktree_path" | shasum | cut -c1-8)
    $TMUX_CMD kill-session -t "=nvim-$nvim_hash" 2>/dev/null || true

    [[ -n "$window_id" ]] && $TMUX_CMD kill-window -t "$window_id"
    return 0
}

if [[ "$mode" == "current" ]]; then
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

    window_id=$($TMUX_CMD display-message -p '#{window_id}')
    remove_worktree "$repo" "$branch" "$window_id"
    exit $?
fi

# --pick mode
require_fzf

session=$($TMUX_CMD display-message -p '#S' 2>/dev/null)
bare_repo="$BARE_DIR/${session}.git"

if [[ ! -d "$bare_repo" ]]; then
    echo "Session '$session' is not a bare repo"
    read -sk1 "?Press any key..."
    exit 1
fi

candidates=()
while IFS= read -r wt; do
    [[ -z "$wt" || "$wt" == "main" || "$wt" == "master" ]] && continue
    candidates+=("$wt")
done < <(list_worktrees "$session")

if (( ${#candidates[@]} == 0 )); then
    echo "No deletable worktrees for $session"
    read -sk1 "?Press any key..."
    exit 0
fi

selection=$(printf '%s\n' "${candidates[@]}" | $FZF_CMD \
    --prompt="Delete worktree: " \
    --reverse \
    --header="Enter = select; Esc = cancel")
fzf_exit=$?

[[ $fzf_exit -eq 130 || -z "$selection" ]] && exit 0

branch="$selection"
window_id=$($TMUX_CMD list-windows -t "=$session" -F '#{window_name}|#{window_id}' 2>/dev/null \
    | awk -F'|' -v n="$branch" '$1==n{print $2; exit}')

remove_worktree "$session" "$branch" "$window_id"
exit $?
