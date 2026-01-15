#!/usr/bin/env zsh
# tmux-nav.sh - Unified fuzzy tmux navigator
# Usage: Run inside tmux, use symbols to filter:
#   @  = sessions only
#   #  = windows only
#   :  = panes only
#   (no prefix) = show all

set -e

[[ -z "$TMUX" ]] && { echo "Error: Run inside tmux"; exit 1; }

# Colors for fzf display
C_SESSION="\033[36m"  # cyan
C_WINDOW="\033[33m"   # yellow
C_PANE="\033[35m"     # magenta
C_RESET="\033[0m"
C_DIM="\033[2m"

# Current context
current_session=$(tmux display-message -p '#S')
current_window=$(tmux display-message -p '#I')
current_pane=$(tmux display-message -p '#P')

# Build unified list
build_list() {
    # Sessions: @session_name (path)
    tmux list-sessions -F "#{session_name}|#{session_path}|#{session_windows}" 2>/dev/null | while IFS='|' read -r name path windows; do
        marker=""
        [[ "$name" == "$current_session" ]] && marker="*"
        echo -e "@${C_SESSION}${name}${marker}${C_RESET} ${C_DIM}(${windows}w)${C_RESET}"
    done

    # Windows: #session:window - name
    tmux list-windows -a -F "#{session_name}|#{window_index}|#{window_name}|#{window_active}" 2>/dev/null | while IFS='|' read -r sess idx name active; do
        marker=""
        [[ "$sess" == "$current_session" && "$idx" == "$current_window" ]] && marker="*"
        echo -e "#${C_WINDOW}${sess}:${idx}${marker}${C_RESET} ${name}"
    done

    # Panes: :session:window.pane - command (path)
    tmux list-panes -a -F "#{session_name}|#{window_index}|#{pane_index}|#{pane_current_command}|#{pane_current_path}" 2>/dev/null | while IFS='|' read -r sess win pane cmd path; do
        marker=""
        [[ "$sess" == "$current_session" && "$win" == "$current_window" && "$pane" == "$current_pane" ]] && marker="*"
        short_path="${path/#$HOME/~}"
        echo -e ":${C_PANE}${sess}:${win}.${pane}${marker}${C_RESET} ${cmd} ${C_DIM}${short_path}${C_RESET}"
    done
}

# Preview function based on selection type
preview_cmd() {
    local sel="$1"
    case "$sel" in
        @*)
            # Session preview: show windows
            local session="${sel#@}"
            session="${session%%\**}"  # Remove marker
            session="${session%% *}"   # Remove trailing info
            echo "Session: $session"
            echo "─────────────────────"
            tmux list-windows -t "$session" -F "  #I: #W #{?window_active,(active),}" 2>/dev/null
            echo ""
            echo "Panes:"
            tmux list-panes -t "$session" -F "  #I.#P: #{pane_current_command}" 2>/dev/null
            ;;
        \#*)
            # Window preview: show panes
            local target="${sel#\#}"
            target="${target%%\**}"
            target="${target%% *}"
            echo "Window: $target"
            echo "─────────────────────"
            tmux list-panes -t "$target" -F "  Pane #P: #{pane_current_command}" 2>/dev/null
            tmux capture-pane -t "$target" -p 2>/dev/null | head -20
            ;;
        :*)
            # Pane preview: show content
            local target="${sel#:}"
            target="${target%%\**}"
            target="${target%% *}"
            echo "Pane: $target"
            echo "─────────────────────"
            tmux capture-pane -t "$target" -p 2>/dev/null | head -30
            ;;
    esac
}

# Export for fzf preview
export -f preview_cmd 2>/dev/null || true

# Find fzf
fzf_cmd=$(command -v fzf || echo "$HOME/.fzf/bin/fzf")
[[ ! -x "$fzf_cmd" ]] && { echo "Error: fzf not found"; exit 1; }

# Create temp preview script (needed because fzf preview can't use functions directly)
preview_script=$(mktemp)
cat > "$preview_script" << 'PREVIEW'
#!/usr/bin/env zsh
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

# Run fzf
selected=$(build_list | "$fzf_cmd" \
    --ansi \
    --reverse \
    --header="@ sessions | # windows | : panes" \
    --preview="$preview_script {}" \
    --preview-window="right:40%:wrap" \
    --bind="@:reload(tmux list-sessions -F '@#S')" \
    --bind="ctrl-s:reload(tmux list-sessions -F '@#S')" \
    --bind="ctrl-w:reload(tmux list-windows -a -F '##{session_name}:#{window_index} #{window_name}')" \
    --bind="ctrl-p:reload(tmux list-panes -a -F ':#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}')")

# Cleanup
rm -f "$preview_script"

# Exit if nothing selected
[[ -z "$selected" ]] && exit 0

# Parse and switch
case "$selected" in
    @*)
        # Switch to session
        target="${selected#@}"
        target="${target%%\**}"
        target="${target%% *}"
        tmux switch-client -t "$target"
        ;;
    \#*)
        # Switch to window
        target="${selected#\#}"
        target="${target%%\**}"
        target="${target%% *}"
        tmux switch-client -t "$target"
        ;;
    :*)
        # Switch to pane
        target="${selected#:}"
        target="${target%%\**}"
        target="${target%% *}"
        tmux switch-client -t "$target"
        ;;
esac
