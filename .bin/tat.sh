#!/usr/bin/env zsh
# tat.sh - Tmux Attach to project
# Simple session manager with zoxide frecency + fzf preview

set -e

PROJECT_ROOT="$HOME/projects"
PREVIEW_SCRIPT="$HOME/.bin/tat-preview.sh"
TEMPLATE_SCRIPT="$HOME/.bin/tat-template.sh"

# Require tmux
[[ -z "$TMUX" ]] && { echo "Error: Run inside tmux"; exit 1; }

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
            local path="$PROJECT_ROOT/$project"
            local score=$(zoxide query -s "$path" 2>/dev/null | awk '{print $1}')
            [[ -z "$score" ]] && score="0"
            echo "$score $project"
        done | sort -rn | awk '{print $2}'
    else
        sort
    fi
}

# Check if session exists
has_session() {
    tmux has-session -t "=$1" 2>/dev/null
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

# Find fzf
fzf_cmd=$(command -v fzf || echo "$HOME/.fzf/bin/fzf")
[[ ! -x "$fzf_cmd" ]] && { echo "Error: fzf not found"; exit 1; }

# Run fzf with preview
selected=$(build_list | "$fzf_cmd" \
    --reverse \
    --ansi \
    --header="Select project (preview: git status, readme)" \
    --preview="$PREVIEW_SCRIPT {2}" \
    --preview-window="right:50%:wrap" \
    | awk '{print $NF}')

# Exit if nothing selected
[[ -z "$selected" ]] && exit 0

session_name="$selected"
project_path="$PROJECT_ROOT/$selected"

# Create or switch to session
if has_session "$session_name"; then
    tmux switch-client -t "$session_name"
else
    "$TEMPLATE_SCRIPT" "$session_name" "$project_path"
fi
