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

# Base tmux session layout: editor with split + git window
# Used by rust, go, and as base for other templates
apply_base_layout() {
    local name="$1" path="$2"
    $TMUX_CMD new-session -d -s "$name" -c "$path" -n "editor"
    $TMUX_CMD send-keys -t "$name:editor" "nvim ." Enter
    $TMUX_CMD split-window -h -t "$name:editor" -c "$path" -l 40%
    $TMUX_CMD new-window -t "$name" -n "git" -c "$path"
    $TMUX_CMD send-keys -t "$name:git" "lazygit" Enter
    $TMUX_CMD select-window -t "$name:editor"
    $TMUX_CMD select-pane -t "$name:editor.0"
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
    NOTE_BRANCH="${NOTE_BRANCH//\//-}"
    return 0
}
