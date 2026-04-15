#!/usr/bin/env zsh
# tmux-edit.sh - Persistent nvim popup, one session per outer tmux session.
# Toggle: C-Space e opens; the binding detaches the inner client to close.
# C-a e/d from inside also dismisses. :qa kills the session entirely.

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init

INNER_SOCKET="nvim"
INNER_CONF="$HOME/.config/nvim/tmux-inner.conf"

outer_session=$($TMUX_CMD display-message -p '#S' 2>/dev/null)
nvim_session="nvim_${outer_session}"
pane_path=$($TMUX_CMD display-message -p '#{pane_current_path}' 2>/dev/null)
pane_path="${pane_path:-$(pwd)}"

if ! tmux -L "$INNER_SOCKET" has-session -t "=$nvim_session" 2>/dev/null; then
    tmux -L "$INNER_SOCKET" -f "$INNER_CONF" new-session -d -s "$nvim_session" -c "$pane_path" \
        nvim .
    tmux -L "$INNER_SOCKET" set-option -t "$nvim_session" status off
fi

# No exec — shell must stay alive so the popup closes when attach-session returns
tmux -L "$INNER_SOCKET" attach-session -t "$nvim_session"
