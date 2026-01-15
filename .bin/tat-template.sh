#!/usr/bin/env zsh
# tat-template.sh - Detect and apply tmux session templates

PROJECT_ROOT="$HOME/projects"

session_name="$1"
project_path="${2:-$PROJECT_ROOT/$session_name}"

# Handle bare repo worktree structure
if [[ -d "$project_path/.bare" ]]; then
    default_branch=$(cd "$project_path/.bare" && git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    [[ -d "$project_path/$default_branch" ]] && project_path="$project_path/$default_branch"
fi

# Detect template type
detect_template() {
    local path="$1"

    # Explicit override via .tmux-template file
    [[ -f "$path/.tmux-template" ]] && { cat "$path/.tmux-template"; return; }

    # Auto-detect by markers
    [[ -f "$path/Cargo.toml" ]] && { echo "rust"; return; }
    [[ -f "$path/package.json" ]] && { echo "node"; return; }
    [[ -f "$path/go.mod" ]] && { echo "go"; return; }
    [[ -f "$path/pyproject.toml" ]] && { echo "python"; return; }
    [[ -f "$path/requirements.txt" ]] && { echo "python"; return; }
    [[ -d "$path/cluster" && -f "$path/Makefile" ]] && { echo "kubernetes"; return; }

    echo "default"
}

# Apply template - creates session with appropriate layout
apply_template() {
    local template="$1"
    local name="$2"
    local path="$3"

    # Add to zoxide for frecency tracking
    command -v zoxide &>/dev/null && zoxide add "$path"

    case "$template" in
        node)
            tmux new-session -d -s "$name" -c "$path" -n "editor"
            tmux send-keys -t "$name:editor" "nvim ." Enter
            tmux split-window -h -t "$name:editor" -c "$path" -l 40%
            tmux new-window -t "$name" -n "server" -c "$path"
            tmux new-window -t "$name" -n "git" -c "$path"
            tmux send-keys -t "$name:git" "lazygit" Enter
            tmux select-window -t "$name:editor"
            tmux select-pane -t "$name:editor.0"
            ;;
        rust)
            tmux new-session -d -s "$name" -c "$path" -n "editor"
            tmux send-keys -t "$name:editor" "nvim ." Enter
            tmux split-window -h -t "$name:editor" -c "$path" -l 40%
            tmux new-window -t "$name" -n "git" -c "$path"
            tmux send-keys -t "$name:git" "lazygit" Enter
            tmux select-window -t "$name:editor"
            tmux select-pane -t "$name:editor.0"
            ;;
        go)
            tmux new-session -d -s "$name" -c "$path" -n "editor"
            tmux send-keys -t "$name:editor" "nvim ." Enter
            tmux split-window -h -t "$name:editor" -c "$path" -l 40%
            tmux new-window -t "$name" -n "git" -c "$path"
            tmux send-keys -t "$name:git" "lazygit" Enter
            tmux select-window -t "$name:editor"
            tmux select-pane -t "$name:editor.0"
            ;;
        python)
            tmux new-session -d -s "$name" -c "$path" -n "editor"
            tmux send-keys -t "$name:editor" "nvim ." Enter
            tmux split-window -h -t "$name:editor" -c "$path" -l 40%
            # Activate venv if exists
            tmux send-keys -t "$name:editor.1" "[ -d .venv ] && source .venv/bin/activate" Enter
            tmux new-window -t "$name" -n "git" -c "$path"
            tmux send-keys -t "$name:git" "lazygit" Enter
            tmux select-window -t "$name:editor"
            tmux select-pane -t "$name:editor.0"
            ;;
        kubernetes)
            tmux new-session -d -s "$name" -c "$path" -n "editor"
            tmux send-keys -t "$name:editor" "nvim ." Enter
            tmux new-window -t "$name" -n "k9s" -c "$path"
            tmux send-keys -t "$name:k9s" "command -v k9s &>/dev/null && k9s || echo 'k9s not installed'" Enter
            tmux new-window -t "$name" -n "git" -c "$path"
            tmux send-keys -t "$name:git" "lazygit" Enter
            tmux select-window -t "$name:editor"
            ;;
        *)
            # Default: simple single window
            tmux new-session -d -s "$name" -c "$path"
            ;;
    esac

    tmux switch-client -t "$name"
}

template=$(detect_template "$project_path")
apply_template "$template" "$session_name" "$project_path"
