#!/usr/bin/env zsh
# tat-template.sh - Create simple tmux session

source "$HOME/.bin/tmux/tmux-lib.sh"

tmux_init

session_name="$1"
project_path="${2:-$(resolve_project_path "$session_name")}"

# Add to zoxide for frecency tracking
command -v zoxide &>/dev/null && zoxide add "$project_path"

# Create session and switch to it (no windows, no programs)
$TMUX_CMD new-session -d -s "$session_name" -c "$project_path"
$TMUX_CMD switch-client -t "$session_name"
