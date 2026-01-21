#!/usr/bin/env zsh
# tat.sh - Tmux Attach to project
# Simple session manager with zoxide frecency + fzf preview

source "$HOME/.bin/tmux-lib.sh"

require_tmux
tmux_init
require_fzf

PREVIEW_SCRIPT="$HOME/.bin/tat-preview.sh"
TEMPLATE_SCRIPT="$HOME/.bin/tat-template.sh"

# Get all project directories
get_projects() {
    local projects=()
    for dir in "$PROJECT_ROOT"/*/; do
        [[ -d "$dir" ]] || continue
        local name=$(basename "$dir")
        [[ "$name" == .* ]] && continue
        projects+=("$name")
    done
    printf '%s\n' "${projects[@]}"
}

# Sort projects by zoxide frecency
sort_by_frecency() {
    if command -v zoxide &>/dev/null; then
        while IFS= read -r project; do
            local ppath="$PROJECT_ROOT/$project"
            local score=$(zoxide query -s "$ppath" 2>/dev/null | /usr/bin/awk '{print $1}')
            [[ -z "$score" ]] && score="0"
            echo "$score $project"
        done | sort -rn | /usr/bin/awk '{print $2}'
    else
        sort
    fi
}

# Check if session exists
has_session() {
    $TMUX_CMD has-session -t "=$1" 2>/dev/null
}

# Build display list with session indicators
build_list() {
    get_projects | sort_by_frecency | while IFS= read -r project; do
        if has_session "$project"; then
            echo "[*] $project"
        else
            echo "    $project"
        fi
    done
}

# Run fzf with preview
selected=$(build_list | "$FZF_CMD" \
    --reverse \
    --ansi \
    --header="Select project (preview: git status, readme)" \
    --preview="$PREVIEW_SCRIPT {-1}" \
    --preview-window="right:50%:wrap" \
    | /usr/bin/awk '{print $NF}')

# Exit if nothing selected
[[ -z "$selected" ]] && exit 0

session_name="$selected"
project_path="$PROJECT_ROOT/$selected"

# Create or switch to session
if has_session "$session_name"; then
    $TMUX_CMD switch-client -t "$session_name"
else
    "$TEMPLATE_SCRIPT" "$session_name" "$project_path"
fi
