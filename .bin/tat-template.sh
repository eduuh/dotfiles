#!/usr/bin/env zsh
# tat-template.sh - Detect and apply tmux session templates

source "$HOME/.bin/tmux-lib.sh"

tmux_init

session_name="$1"
project_path=$(resolve_project_path "${2:-$PROJECT_ROOT/$session_name}")

# Apply template based on project type
apply_template() {
    local template="$1"
    local name="$2"
    local path="$3"

    # Add to zoxide for frecency tracking
    command -v zoxide &>/dev/null && zoxide add "$path"

    case "$template" in
        node)
            apply_base_layout "$name" "$path"
            $TMUX_CMD new-window -t "$name" -n "server" -c "$path"
            # Reorder: editor, server, git
            $TMUX_CMD move-window -t "$name:server" -s "$name:2"
            ;;
        rust|go)
            apply_base_layout "$name" "$path"
            ;;
        python)
            apply_base_layout "$name" "$path"
            # Activate venv if exists
            $TMUX_CMD send-keys -t "$name:editor.1" "[ -d .venv ] && source .venv/bin/activate" Enter
            ;;
        kubernetes)
            $TMUX_CMD new-session -d -s "$name" -c "$path" -n "editor"
            $TMUX_CMD send-keys -t "$name:editor" "nvim ." Enter
            $TMUX_CMD new-window -t "$name" -n "k9s" -c "$path"
            $TMUX_CMD send-keys -t "$name:k9s" "command -v k9s &>/dev/null && k9s || echo 'k9s not installed'" Enter
            $TMUX_CMD new-window -t "$name" -n "git" -c "$path"
            $TMUX_CMD send-keys -t "$name:git" "lazygit" Enter
            $TMUX_CMD select-window -t "$name:editor"
            ;;
        *)
            $TMUX_CMD new-session -d -s "$name" -c "$path"
            ;;
    esac

    $TMUX_CMD switch-client -t "$name"
}

template=$(detect_project_type "$project_path")
apply_template "$template" "$session_name" "$project_path"
