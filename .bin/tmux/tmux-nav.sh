#!/usr/bin/env zsh
# tmux-nav.sh - Unified fuzzy tmux navigator
# Usage: Run inside tmux, use symbols to filter:
#   @  = sessions only
#   #  = windows only
#   :  = panes only
#   (no prefix) = show all

source "$HOME/.bin/tmux/tmux-lib.sh"

require_tmux
tmux_init
require_fzf

# Colors for fzf display
C_SESSION="\033[36m"  # cyan
C_WINDOW="\033[33m"   # yellow
C_PANE="\033[35m"     # magenta
C_RESET="\033[0m"
C_DIM="\033[2m"

# Current context
current_session=$($TMUX_CMD display-message -p '#S')
current_window=$($TMUX_CMD display-message -p '#I')
current_pane=$($TMUX_CMD display-message -p '#P')

# Build unified list
build_list() {
    # Sessions: @session_name (windows)
    $TMUX_CMD list-sessions -F "#{session_name}|#{session_path}|#{session_windows}" 2>/dev/null | while IFS='|' read -r name path windows; do
        marker=""
        [[ "$name" == "$current_session" ]] && marker="*"
        echo -e "@${C_SESSION}${name}${marker}${C_RESET} ${C_DIM}(${windows}w)${C_RESET}"
    done

    # Windows: #session:window - name
    $TMUX_CMD list-windows -a -F "#{session_name}|#{window_index}|#{window_name}|#{window_active}" 2>/dev/null | while IFS='|' read -r sess idx name active; do
        marker=""
        [[ "$sess" == "$current_session" && "$idx" == "$current_window" ]] && marker="*"
        echo -e "#${C_WINDOW}${sess}:${idx}${marker}${C_RESET} ${name}"
    done

    # Panes: :session:window.pane - command (path)
    $TMUX_CMD list-panes -a -F "#{session_name}|#{window_index}|#{pane_index}|#{pane_current_command}|#{pane_current_path}" 2>/dev/null | while IFS='|' read -r sess win pane cmd path; do
        marker=""
        [[ "$sess" == "$current_session" && "$win" == "$current_window" && "$pane" == "$current_pane" ]] && marker="*"
        short_path="${path/#$HOME/~}"
        echo -e ":${C_PANE}${sess}:${win}.${pane}${marker}${C_RESET} ${cmd} ${C_DIM}${short_path}${C_RESET}"
    done
}

# Create temp preview script (fzf preview can't use shell functions)
preview_script=$(mktemp)
cat > "$preview_script" << 'PREVIEW'
#!/usr/bin/env zsh
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
sel="$1"
case "$sel" in
    @*)
        session="${sel#@}"
        session="${session%%\**}"
        session="${session%% *}"
        echo "Session: $session"
        echo "─────────────────────"
        tmux list-windows -t "$session" -F "  #I: #W #{?window_active,(active),}" 2>/dev/null
        echo ""
        echo "Panes:"
        tmux list-panes -t "$session" -F "  #I.#P: #{pane_current_command}" 2>/dev/null
        ;;
    \#*)
        target="${sel#\#}"
        target="${target%%\**}"
        target="${target%% *}"
        echo "Window: $target"
        echo "─────────────────────"
        tmux list-panes -t "$target" -F "  Pane #P: #{pane_current_command}" 2>/dev/null
        echo ""
        tmux capture-pane -t "$target" -p 2>/dev/null | head -15
        ;;
    :*)
        target="${sel#:}"
        target="${target%%\**}"
        target="${target%% *}"
        echo "Pane: $target"
        echo "─────────────────────"
        tmux capture-pane -t "$target" -p 2>/dev/null | head -25
        ;;
esac
PREVIEW
chmod +x "$preview_script"

# Create rename helper script for fzf execute binding
rename_script=$(mktemp)
cat > "$rename_script" << 'RENAME'
#!/usr/bin/env zsh
sel="$1"
# Only works for sessions (@prefix)
[[ "$sel" != @* ]] && exit 0
session="${sel#@}"
session="${session%%\**}"
session="${session%% *}"
# Remove ANSI codes
session=$(echo "$session" | sed 's/\x1b\[[0-9;]*m//g')
# Use tmux command-prompt for rename
tmux command-prompt -p "Rename '$session' to:" "rename-session -t '$session' '%%'"
RENAME
chmod +x "$rename_script"

# Run fzf
selected=$(build_list | "$FZF_CMD" \
    --ansi \
    --reverse \
    --header="@ sessions | # windows | : panes | ctrl-r: rename session" \
    --preview="$preview_script {}" \
    --preview-window="right:40%:wrap" \
    --bind="@:reload(tmux list-sessions -F '@#S')" \
    --bind="ctrl-s:reload(tmux list-sessions -F '@#S')" \
    --bind="ctrl-w:reload(tmux list-windows -a -F '##{session_name}:#{window_index} #{window_name}')" \
    --bind="ctrl-p:reload(tmux list-panes -a -F ':#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}')" \
    --bind="ctrl-r:execute-silent($rename_script {})+reload(sleep 0.2 && $0)")

# Cleanup
rm -f "$preview_script" "$rename_script"

# Exit if nothing selected
[[ -z "$selected" ]] && exit 0

# Parse selection and extract target
target="${selected#[@#:]}"  # Remove prefix
target="${target%%\**}"     # Remove marker
target="${target%% *}"      # Remove trailing info

# Switch to target
$TMUX_CMD switch-client -t "$target"
