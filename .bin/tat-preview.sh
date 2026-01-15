#!/usr/bin/env zsh
# tat-preview.sh - fzf preview for project selection

source "$HOME/.bin/tmux-lib.sh"

project="$1"
path=$(resolve_project_path "$PROJECT_ROOT/$project")

[[ ! -d "$path" ]] && { echo "Directory not found: $path"; exit 1; }

# Header
echo "━━━ $project ━━━"
echo ""

# Git info
if [[ -d "$path/.git" ]] || [[ -d "$path/.bare" ]]; then
    cd "$path"
    branch=$(git branch --show-current 2>/dev/null || echo "detached")

    echo "Branch: $branch"

    # Status summary
    staged=${#${(f)"$(git diff --cached --numstat 2>/dev/null)"}}
    unstaged=${#${(f)"$(git diff --numstat 2>/dev/null)"}}
    untracked=${#${(f)"$(git ls-files --others --exclude-standard 2>/dev/null)"}}

    [[ "$staged" -gt 0 ]] && echo "Staged: $staged"
    [[ "$unstaged" -gt 0 ]] && echo "Modified: $unstaged"
    [[ "$untracked" -gt 0 ]] && echo "Untracked: $untracked"
    [[ "$staged" -eq 0 && "$unstaged" -eq 0 && "$untracked" -eq 0 ]] && echo "Clean"

    echo ""
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null
    echo ""
fi

# Project type detection
project_type=$(detect_project_type "$path")
echo "Type: $(project_type_display "$project_type")"

# Extra info for Node.js projects
if [[ "$project_type" == "node" ]] && command -v jq &>/dev/null; then
    scripts=$(jq -r '.scripts | keys | join(", ")' "$path/package.json" 2>/dev/null)
    [[ -n "$scripts" ]] && echo "Scripts: ${scripts:0:60}"
fi
echo ""

# README preview
for readme in README.md readme.md README.rst README; do
    if [[ -f "$path/$readme" ]]; then
        echo "━━━ README ━━━"
        if command -v bat &>/dev/null; then
            bat --style=plain --color=always --line-range=:15 "$path/$readme" 2>/dev/null
        else
            local i=0
            while IFS= read -r line && (( i++ < 15 )); do
                echo "$line"
            done < "$path/$readme"
        fi
        break
    fi
done
