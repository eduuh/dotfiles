#!/usr/bin/env zsh
# tmux-note.sh - Persistent branch note popup, one session per outer tmux session.
# Toggle: C-Space n opens; the binding detaches the inner client to close.
# C-a n/d from inside also dismisses. :q kills the session entirely.

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init

INNER_SOCKET="nvim"
INNER_CONF="$HOME/.config/nvim/tmux-inner.conf"

outer_session=$($TMUX_CMD display-message -p '#S' 2>/dev/null)
note_session="note_${outer_session}"
pane_path=$($TMUX_CMD display-message -p '#{pane_current_path}' 2>/dev/null)
pane_path="${pane_path:-$(pwd)}"

if ! tmux -L "$INNER_SOCKET" has-session -t "=$note_session" 2>/dev/null; then
    note_dir=$(cd "$pane_path" && "$HOME/.bin/bn" 2>/dev/null)
    note_file="${note_dir}/note.md"

    $TMUX_CMD list-windows -F '#{window_name}' 2>/dev/null | while IFS= read -r win; do
        if ! grep -Fq "### $win" "$note_file" 2>/dev/null; then
            printf '\n### %s\n' "$win" >> "$note_file"
        fi
    done

    tmux -L "$INNER_SOCKET" -f "$INNER_CONF" new-session -d -s "$note_session" -c "$pane_path" \
        nvim "$note_file"
    tmux -L "$INNER_SOCKET" set-option -t "$note_session" status off
fi

# No exec — shell must stay alive so the popup closes when attach-session returns
tmux -L "$INNER_SOCKET" attach-session -t "$note_session"
