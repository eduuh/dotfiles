#!/usr/bin/env zsh
# tmux-lib.sh - Shared utilities for tmux scripts

# PATH setup
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Constants
PROJECT_ROOT="$HOME/projects"

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

# Resolve bare repo worktree path
# Usage: path=$(resolve_project_path "$path")
resolve_project_path() {
    local path="$1"
    if [[ -d "$path/.bare" ]]; then
        local default_branch=$(cd "$path/.bare" && git symbolic-ref --short HEAD 2>/dev/null || echo "main")
        [[ -d "$path/$default_branch" ]] && path="$path/$default_branch"
    fi
    echo "$path"
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
