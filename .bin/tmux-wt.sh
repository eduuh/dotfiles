#!/usr/bin/env zsh
# tmux-wt.sh - Unified worktree manager popup (create/remove)
# Bound to prefix+W in tmux

source "$HOME/.bin/tmux-lib.sh"
tmux_init
require_fzf

# Step 1: Action picker
action=$(printf 'Create worktree\nRemove worktree' | $FZF_CMD --prompt="Action: " --reverse)
[[ -z "$action" ]] && exit 0

#============================================================================
# Create worktree
#============================================================================
if [[ "$action" == "Create worktree" ]]; then
    # 1. List bare repos → fzf picker
    bare_repos=("$BARE_DIR"/*.git(N/))
    [[ ${#bare_repos[@]} -eq 0 ]] && { echo "No bare repos found in $BARE_DIR"; read -sk1; exit 1; }

    repo_names=()
    for bare in "${bare_repos[@]}"; do
        repo_names+=($(basename "$bare" .git))
    done

    selected=$(printf '%s\n' "${repo_names[@]}" | $FZF_CMD --prompt="Repo: " --reverse)
    [[ -z "$selected" ]] && exit 0

    bare_repo="$BARE_DIR/${selected}.git"

    # 2. Prompt for branch name
    printf "Branch name: "
    read -r branch_name
    [[ -z "$branch_name" ]] && exit 0

    sanitized=$(echo "$branch_name" | tr '/' '-')
    worktree_path="$WORKTREE_DIR/${selected}/${sanitized}"

    if [[ -d "$worktree_path" ]]; then
        echo "Worktree already exists: $worktree_path"
        read -sk1 "?Press any key..."
        exit 0
    fi

    # 3. Fetch + reset main + create worktree
    echo "Fetching origin..."
    git --git-dir="$bare_repo" fetch origin

    echo "Updating main → origin/main..."
    git --git-dir="$bare_repo" branch -f main origin/main 2>/dev/null

    echo "Creating worktree: $worktree_path"
    mkdir -p "$WORKTREE_DIR/${selected}"
    git --git-dir="$bare_repo" worktree add -b "$branch_name" "$worktree_path" main

    if [[ $? -ne 0 ]]; then
        echo "Failed to create worktree"
        read -sk1 "?Press any key..."
        exit 1
    fi

    echo "Done!"

    # 4. Open tmux session in new worktree
    session_name="${selected}/${sanitized}"
    "$HOME/.bin/tat-template.sh" "$session_name" "$worktree_path"

#============================================================================
# Remove worktree
#============================================================================
elif [[ "$action" == "Remove worktree" ]]; then
    removed=0

    while true; do
        # 1. Gather worktrees from all bare repos
        entries=()
        for bare in "$BARE_DIR"/*.git(N/); do
            local repo_name=$(basename "$bare" .git)
            local wt_lines=("${(@f)$(git --git-dir="$bare" worktree list --porcelain | grep '^worktree ')}")
            for line in "${wt_lines[@]}"; do
                local wt_path="${line#worktree }"
                [[ "$wt_path" == "$BARE_DIR"/* ]] && continue
                local branch_dir=$(basename "$wt_path")
                # Skip main/master — these should never be removed
                [[ "$branch_dir" == "main" || "$branch_dir" == "master" ]] && continue
                entries+=("${repo_name}/${branch_dir}\t${wt_path}")
            done
        done

        [[ ${#entries[@]} -eq 0 ]] && { echo "No worktrees found"; break; }

        # 2. Display in fzf picker
        selected=$(printf '%s\n' "${entries[@]}" | cut -f1 | $FZF_CMD --prompt="Remove: " --reverse)
        [[ -z "$selected" ]] && break

        # Find the full path for the selected entry
        selected_path=""
        for entry in "${entries[@]}"; do
            local display="${entry%%$'\t'*}"
            local path="${entry#*$'\t'}"
            if [[ "$display" == "$selected" ]]; then
                selected_path="$path"
                break
            fi
        done

        [[ -z "$selected_path" ]] && { echo "Error: could not resolve path"; break; }

        # 3. Find the bare repo for this worktree
        local repo_name="${selected%%/*}"
        local bare_repo="$BARE_DIR/${repo_name}.git"

        if [[ ! -d "$bare_repo" ]]; then
            echo "Error: bare repo not found: $bare_repo"
            break
        fi

        # 4. Remove worktree
        echo "Removing: $selected"
        if ! git --git-dir="$bare_repo" worktree remove "$selected_path"; then
            echo "Failed to remove worktree"
            read -sk1 "?Press any key..."
            break
        fi

        # 5. Clean up empty repo directory
        local repo_dir=$(dirname "$selected_path")
        if [[ "$repo_dir" == "$WORKTREE_DIR"/* ]] && [[ -d "$repo_dir" ]]; then
            rmdir "$repo_dir" 2>/dev/null || true
        fi

        # 6. Kill tmux session if it exists
        $TMUX_CMD kill-session -t "$selected" 2>/dev/null || true

        echo "Removed: $selected"
        removed=$((removed + 1))
    done

    # 7. Prune orphaned branch notes (once, after all removals)
    if (( removed > 0 )); then
        "$HOME/.bin/branch-note.sh" prune
    fi
fi
