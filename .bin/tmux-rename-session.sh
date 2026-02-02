#!/usr/bin/env zsh
# tmux-rename-session.sh - Pick and rename any tmux session
# Useful for renaming cloned project sessions (1js, 1js2, etc.) to meaningful names

source "$HOME/.bin/tmux-lib.sh"

require_tmux
tmux_init
require_fzf

# Colors
C_SESSION="\033[36m"  # cyan
C_RESET="\033[0m"
C_DIM="\033[2m"

current_session=$($TMUX_CMD display-message -p '#S')

# Build session list
build_list() {
    $TMUX_CMD list-sessions -F "#{session_name}|#{session_windows}|#{session_path}" 2>/dev/null | while IFS='|' read -r name windows path; do
        marker=""
        [[ "$name" == "$current_session" ]] && marker=" *"
        short_path="${path/#$HOME/~}"
        echo -e "${C_SESSION}${name}${marker}${C_RESET} ${C_DIM}(${windows}w) ${short_path}${C_RESET}"
    done
}

# Select session to rename
selected=$(build_list | "$FZF_CMD" \
    --ansi \
    --reverse \
    --header="Select session to rename (Enter to select)" \
    --preview="tmux list-windows -t {1} -F '  #I: #W' 2>/dev/null" \
    --preview-window="right:40%:wrap")

[[ -z "$selected" ]] && exit 0

# Extract session name (first word, without color codes and marker)
old_name=$(echo "$selected" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}' | sed 's/\*$//')

# Prompt for new name using tmux command-prompt
# We use a temp file to pass the new name since command-prompt runs asynchronously
tmpfile=$(mktemp)

$TMUX_CMD command-prompt -p "Rename '$old_name' to:" \
    "run-shell \"echo '%1' > $tmpfile && tmux rename-session -t '$old_name' '%1' && rm -f $tmpfile\" "
