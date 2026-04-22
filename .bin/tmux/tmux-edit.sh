#!/usr/bin/env zsh
# tmux-edit.sh - Toggle a floating nvim scoped to the current worktree.
#
# Only one nvim session ever exists server-wide. Opening the popup from a
# different worktree kills any prior nvim-* session and spawns a fresh one
# at the new worktree's cwd, so tmux always reflects the right worktree.
# Pressing the same bind from inside the popup detaches the client —
# popup closes, nvim keeps running until the next worktree switch.
source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init

pane_path=$("$TMUX_CMD" display-message -p '#{pane_current_path}')
[[ -d "$pane_path" ]] || pane_path="$HOME"

hash=$(printf '%s' "$pane_path" | shasum | cut -c1-8)
session="nvim-$hash"

current_session=$("$TMUX_CMD" display-message -p '#{session_name}')
if [[ "$current_session" == "$session" ]]; then
    exec "$TMUX_CMD" detach-client
fi

# Enforce one-nvim-at-a-time: kill any stale nvim-* sessions from prior
# worktrees before attaching/creating the one for this worktree.
"$TMUX_CMD" list-sessions -F '#S' 2>/dev/null | while IFS= read -r s; do
    [[ "$s" == nvim-* && "$s" != "$session" ]] \
        && "$TMUX_CMD" kill-session -t "=$s" 2>/dev/null
done

if ! "$TMUX_CMD" has-session -t "=$session" 2>/dev/null; then
    "$TMUX_CMD" new-session -d -s "$session" -c "$pane_path" 'nvim .'
fi

"$TMUX_CMD" popup -d "$pane_path" -xC -yC -w 97% -h 97% -E \
    "tmux attach -t '=$session'"
