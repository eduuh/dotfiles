#!/usr/bin/env zsh
# tmux-wt.sh - Unified worktree manager popup (create/remove)
# Bound to prefix+W in tmux
# Usage: tmux-wt.sh [current_pane_path]

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init
require_fzf

NOTES_DIR="$HOME/projects/personal-notes/branch-notes"
CURRENT_PATH="${1:-}"

# Auto-detect repo from current path (if inside a worktree)
auto_detect_repo() {
    if [[ -n "$CURRENT_PATH" && "$CURRENT_PATH" == "$WORKTREE_DIR"/* ]]; then
        local rel="${CURRENT_PATH#$WORKTREE_DIR/}"
        echo "${rel%%/*}"
    fi
}

# Step 1: Action picker
action=$(printf 'Create worktree\nRemove worktree' | $FZF_CMD --prompt="Action: " --reverse)
[[ -z "$action" ]] && exit 0

#============================================================================
# Create worktree
#============================================================================
if [[ "$action" == "Create worktree" ]]; then
    # Auto-detect repo or show picker
    detected_repo=$(auto_detect_repo)

    if [[ -n "$detected_repo" && -d "$BARE_DIR/${detected_repo}.git" ]]; then
        selected="$detected_repo"
        echo "Repo: $selected (auto-detected)"
    else
        # List bare repos → fzf picker
        bare_repos=("$BARE_DIR"/*.git(N/))
        [[ ${#bare_repos[@]} -eq 0 ]] && { echo "No bare repos found in $BARE_DIR"; read -sk1; exit 1; }

        repo_names=()
        for bare in "${bare_repos[@]}"; do
            repo_names+=($(basename "$bare" .git))
        done

        selected=$(printf '%s\n' "${repo_names[@]}" | $FZF_CMD --prompt="Repo: " --reverse)
        [[ -z "$selected" ]] && exit 0
    fi

    bare_repo="$BARE_DIR/${selected}.git"

    # 2. Fetch + update main
    echo "Fetching origin..."
    git --git-dir="$bare_repo" fetch origin

    echo "Updating main → origin/main..."
    git --git-dir="$bare_repo" branch -f main origin/main 2>/dev/null

    # 3. New branch vs existing branch picker
    branch_mode=$(printf 'New branch\nExisting branch' | $FZF_CMD --prompt="Branch type: " --reverse)
    [[ -z "$branch_mode" ]] && exit 0

    if [[ "$branch_mode" == "Existing branch" ]]; then
        # Pick from remote branches (strip origin/ prefix, deduplicate)
        branch_name=$(git --git-dir="$bare_repo" branch -a --format='%(refname:short)' | \
            sed 's|^origin/||' | sort -u | grep -v '^HEAD$' | \
            $FZF_CMD --prompt="Branch: " --reverse)
        [[ -z "$branch_name" ]] && exit 0
    else
        printf "Branch name: "
        read -r branch_name
        [[ -z "$branch_name" ]] && exit 0
    fi

    sanitized=$(echo "$branch_name" | tr '/' '-')
    worktree_path="$WORKTREE_DIR/${selected}/${sanitized}"

    if [[ -d "$worktree_path" ]]; then
        echo "Worktree already exists: $worktree_path"
        read -sk1 "?Press any key..."
        exit 0
    fi

    # 4. Create worktree
    echo "Creating worktree: $worktree_path"
    mkdir -p "$WORKTREE_DIR/${selected}"
    if [[ "$branch_mode" == "Existing branch" ]]; then
        # Check if local branch exists, otherwise track from remote
        if git --git-dir="$bare_repo" show-ref --verify --quiet "refs/heads/$branch_name"; then
            git --git-dir="$bare_repo" worktree add "$worktree_path" "$branch_name"
        elif git --git-dir="$bare_repo" show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
            git --git-dir="$bare_repo" worktree add "$worktree_path" "$branch_name"
        else
            echo "Branch '$branch_name' not found"
            read -sk1 "?Press any key..."
            exit 1
        fi
    else
        git --git-dir="$bare_repo" worktree add -b "$branch_name" "$worktree_path" main
    fi

    if [[ $? -ne 0 ]]; then
        echo "Failed to create worktree"
        read -sk1 "?Press any key..."
        exit 1
    fi

    # 5. Pull latest into the new worktree
    echo "Pulling latest..."
    git -C "$worktree_path" pull --ff-only 2>/dev/null || true

    # 6. Run bn build script if it exists for this repo
    (cd "$worktree_path" && "$HOME/.bin/bn" build 2>/dev/null) || true

    echo "Done!"

    # 7. Open tmux session in new worktree
    session_name="${selected}/${sanitized}"
    "$HOME/.bin/tmux/tat-template.sh" "$session_name" "$worktree_path"

#============================================================================
# Remove worktree
#============================================================================
elif [[ "$action" == "Remove worktree" ]]; then
    removed=0

    while true; do
        # 1. Gather worktree display names (repo/branch) from all bare repos
        names=()
        for bare in "$BARE_DIR"/*.git(N/); do
            repo_name=$(basename "$bare" .git)
            wt_lines=("${(@f)$(git --git-dir="$bare" worktree list --porcelain | grep '^worktree ')}")
            for line in "${wt_lines[@]}"; do
                wt_path="${line#worktree }"
                [[ "$wt_path" == "$BARE_DIR"/* ]] && continue
                branch_dir=$(basename "$wt_path")
                [[ "$branch_dir" == "main" || "$branch_dir" == "master" ]] && continue
                names+=("${repo_name}/${branch_dir}")
            done
        done

        [[ ${#names[@]} -eq 0 ]] && { echo "No worktrees found"; break; }

        # 2. fzf picker
        selected=$(printf '%s\n' "${names[@]}" | $FZF_CMD --prompt="Remove: " --reverse)
        [[ -z "$selected" ]] && break

        # 3. Derive paths from selection (repo/branch)
        repo_name="${selected%%/*}"
        branch_dir="${selected#*/}"
        selected_path="$WORKTREE_DIR/${repo_name}/${branch_dir}"
        bare_repo="$BARE_DIR/${repo_name}.git"

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
        repo_dir="$WORKTREE_DIR/${repo_name}"
        if [[ -d "$repo_dir" ]]; then
            rmdir "$repo_dir" 2>/dev/null || true
        fi

        # 6. Kill tmux session if it exists
        $TMUX_CMD kill-session -t "$selected" 2>/dev/null || true

        echo "Removed: $selected"
        removed=$((removed + 1))
    done

    # 7. Prune orphaned branch notes (once, after all removals)
    if (( removed > 0 )); then
        "$HOME/.bin/bn" prune
    fi
fi
