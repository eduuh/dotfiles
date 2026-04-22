#!/usr/bin/env zsh
# tat-template.sh - Create simple tmux session with a `main` window

source "$HOME/.bin/tmux/tmux-lib.sh"

tmux_init

session_name="$1"
project_path="${2:-$(resolve_project_path "$session_name")}"

if is_bare_repo "$session_name"; then
    ensure_worktree "$session_name" "main" >/dev/null 2>&1 || true
    start_path=$(bare_repo_main_path "$session_name")
else
    start_path="$project_path"
fi

command -v zoxide &>/dev/null && zoxide add "$start_path"

$TMUX_CMD new-session -d -s "$session_name" -n main -c "$start_path"
$TMUX_CMD switch-client -t "$session_name"
