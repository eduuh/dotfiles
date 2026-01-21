#!/usr/bin/env zsh
# tmux-apps.sh - Launch common applications via fzf popup
# Supports both TUI (terminal) and GUI apps on Mac and WSL

source "$HOME/.bin/tmux-lib.sh"

APPS_FILE="$HOME/.apps.list"

# Detect platform
get_platform() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "mac"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    else
        echo "linux"
    fi
}

# Parse apps file and filter by platform
get_apps() {
    local platform=$(get_platform)

    [[ ! -f "$APPS_FILE" ]] && {
        echo "Error: $APPS_FILE not found" >&2
        echo "Create it with format: name:command:type:platform" >&2
        exit 1
    }

    while IFS=: read -r name cmd type plat; do
        # Skip comments and empty lines
        [[ -z "$name" || "$name" == \#* ]] && continue

        # Trim whitespace
        name="${name## }"; name="${name%% }"
        cmd="${cmd## }"; cmd="${cmd%% }"
        type="${type## }"; type="${type%% }"
        plat="${plat## }"; plat="${plat%% }"

        # Default platform to 'all' if not specified
        [[ -z "$plat" ]] && plat="all"

        # Filter by platform
        if [[ "$plat" == "all" || "$plat" == "$platform" ]]; then
            # Format: icon name | command | type
            local icon=""
            case "$type" in
                gui) icon="󰖟" ;;  # GUI app icon
                *)   icon="" ;;  # Terminal icon
            esac
            echo "$icon $name|$cmd|$type"
        fi
    done < "$APPS_FILE"
}

# Main
require_fzf

apps=$(get_apps)
[[ -z "$apps" ]] && { echo "No apps configured for this platform"; exit 1; }

# fzf selection
selected=$(echo "$apps" | $FZF_CMD \
    --ansi \
    --reverse \
    --border \
    --prompt="Launch: " \
    --header="Select an application" \
    --delimiter="|" \
    --with-nth=1 \
    --preview-window=hidden)

[[ -z "$selected" ]] && exit 0

# Parse selection
cmd=$(echo "$selected" | cut -d'|' -f2)
type=$(echo "$selected" | cut -d'|' -f3)

# Launch based on type
case "$type" in
    gui)
        # GUI apps: launch detached and exit
        eval "$cmd" &>/dev/null &
        disown
        ;;
    *)
        # TUI apps: run in current terminal
        eval "$cmd"
        ;;
esac
