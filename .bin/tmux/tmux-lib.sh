#!/usr/bin/env zsh
# tmux-lib.sh - Shared utilities for tmux scripts

# PATH setup
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Constants
PROJECT_ROOT="$HOME/projects"
BARE_DIR="$PROJECT_ROOT/bare"
WORKTREE_DIR="$PROJECT_ROOT/worktree"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Find tmux command and set TMUX_CMD
tmux_init() {
    TMUX_CMD=$(command -v tmux)
    [[ -z "$TMUX_CMD" ]] && { echo "Error: tmux not found"; exit 1; }
}

# Require running inside tmux
require_tmux() {
    [[ -z "$TMUX" ]] && { echo "Error: Run inside tmux"; exit 1; }
}

# Find fzf command and set FZF_CMD
require_fzf() {
    FZF_CMD=$(command -v fzf || echo "$HOME/.fzf/bin/fzf")
    [[ ! -x "$FZF_CMD" ]] && { echo "Error: fzf not found"; exit 1; }
}

# Resolve project name to full path
# If name contains "/" (e.g. "kube-homelab/main") → worktree path
# Otherwise → regular clone at project root
# Usage: path=$(resolve_project_path "$name")
resolve_project_path() {
    local name="$1"
    if [[ "$name" == */* ]]; then
        echo "$WORKTREE_DIR/$name"
    else
        echo "$PROJECT_ROOT/$name"
    fi
}

# Check if a project name is a bare repo
is_bare_repo() {
    [[ -d "$BARE_DIR/${1}.git" ]]
}

# Resolve the main worktree path for a bare repo
bare_repo_main_path() {
    local main_wt="$WORKTREE_DIR/$1/main"
    [[ -d "$main_wt" ]] && echo "$main_wt" || echo "$BARE_DIR/${1}.git"
}

# Detect project type by marker files
# Returns: rust, node, go, python, kubernetes, or default
detect_project_type() {
    local path="$1"
    # Check for explicit override
    [[ -f "$path/.tmux-template" ]] && { cat "$path/.tmux-template"; return; }
    # Auto-detect
    [[ -f "$path/Cargo.toml" ]] && { echo "rust"; return; }
    [[ -f "$path/package.json" ]] && { echo "node"; return; }
    [[ -f "$path/go.mod" ]] && { echo "go"; return; }
    [[ -f "$path/pyproject.toml" ]] && { echo "python"; return; }
    [[ -f "$path/requirements.txt" ]] && { echo "python"; return; }
    [[ -d "$path/cluster" && -f "$path/Makefile" ]] && { echo "kubernetes"; return; }
    echo "default"
}

# Get display name for project type
project_type_display() {
    case "$1" in
        rust) echo "Rust" ;;
        node) echo "Node.js" ;;
        go) echo "Go" ;;
        python) echo "Python" ;;
        kubernetes) echo "Kubernetes" ;;
        *) echo "Unknown" ;;
    esac
}

# List worktrees for a bare repo (excluding main/master and the bare dir itself)
# Usage: list_worktrees "repo-name"  →  prints "branch-dir" per line
list_worktrees() {
    local repo="$1"
    local bare="$BARE_DIR/${repo}.git"
    [[ -d "$bare" ]] || return 1
    git --git-dir="$bare" worktree list --porcelain 2>/dev/null | while IFS= read -r line; do
        [[ "$line" == worktree\ * ]] || continue
        local wt_path="${line#worktree }"
        [[ "$wt_path" == "$BARE_DIR"/* ]] && continue
        echo "$(basename "$wt_path")"
    done
}

# Count windows in a tmux session (0 if session doesn't exist)
session_window_count() {
    $TMUX_CMD list-windows -t "=$1" -F x 2>/dev/null | wc -l
}

# Ensure a worktree exists for repo/branch; create from latest main if missing.
# Prints progress to stdout (intended for interactive popups).
# Usage: ensure_worktree <repo> <branch>
# Returns 0 on success, 1 on failure.
ensure_worktree() {
    local repo="$1"
    local branch="$2"
    [[ -z "$repo" || -z "$branch" ]] && { echo "ensure_worktree: missing repo/branch"; return 1; }
    local bare="$BARE_DIR/${repo}.git"
    [[ -d "$bare" ]] || { echo "Not a bare repo: $repo"; return 1; }
    local sanitized="${branch//\//-}"
    local worktree_path="$WORKTREE_DIR/$repo/$sanitized"
    [[ -d "$worktree_path" ]] && return 0
    echo "Creating worktree: $worktree_path"
    echo "Fetching origin..."
    git --git-dir="$bare" fetch origin || { echo "Fetch failed"; return 1; }
    git --git-dir="$bare" branch -f main origin/main 2>/dev/null
    mkdir -p "$WORKTREE_DIR/$repo"
    if git --git-dir="$bare" show-ref --verify --quiet "refs/heads/$branch"; then
        if ! git --git-dir="$bare" worktree add "$worktree_path" "$branch"; then
            echo "Failed to create worktree"
            return 1
        fi
    else
        if ! git --git-dir="$bare" worktree add -b "$branch" "$worktree_path" main; then
            echo "Failed to create worktree"
            return 1
        fi
    fi
    (cd "$worktree_path" && "$HOME/.bin/bn" build 2>/dev/null) || true
    return 0
}

# Ensure the main worktree exists for a bare repo. No-op for non-bare repos.
# Usage: ensure_main_worktree <repo>
ensure_main_worktree() {
    local repo="$1"
    [[ -z "$repo" ]] && return 1
    is_bare_repo "$repo" || return 0
    ensure_worktree "$repo" "main"
}

# Resolve repo name and branch from a directory path
# Sets: NOTE_REPO, NOTE_BRANCH (slashes sanitized to dashes)
resolve_note_context() {
    local dir="$1"
    if [[ "$dir" == "$WORKTREE_DIR"/* ]]; then
        local rel="${dir#$WORKTREE_DIR/}"
        NOTE_REPO="${rel%%/*}"
        NOTE_BRANCH=$(git -C "$dir" branch --show-current 2>/dev/null)
    else
        NOTE_REPO=$(basename "$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)")
        NOTE_BRANCH=$(git -C "$dir" branch --show-current 2>/dev/null)
    fi
    [[ -z "$NOTE_REPO" || -z "$NOTE_BRANCH" ]] && return 1
    NOTE_REPO="${NOTE_REPO:l}"
    NOTE_BRANCH="${NOTE_BRANCH//\//-}"
    return 0
}
