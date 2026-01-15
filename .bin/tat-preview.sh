#!/usr/bin/env zsh
# tat-preview.sh - fzf preview for project selection

PROJECT_ROOT="$HOME/projects"
project="$1"
path="$PROJECT_ROOT/$project"

# Handle bare repo worktree structure
if [[ -d "$path/.bare" ]]; then
    default_branch=$(cd "$path/.bare" && git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    [[ -d "$path/$default_branch" ]] && path="$path/$default_branch"
fi

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
    staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    unstaged=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    [[ "$staged" -gt 0 ]] && echo "Staged: $staged"
    [[ "$unstaged" -gt 0 ]] && echo "Modified: $unstaged"
    [[ "$untracked" -gt 0 ]] && echo "Untracked: $untracked"
    [[ "$staged" -eq 0 && "$unstaged" -eq 0 && "$untracked" -eq 0 ]] && echo "Clean"

    echo ""
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null | head -5
    echo ""
fi

# Project type detection
echo "Type: \c"
if [[ -f "$path/Cargo.toml" ]]; then
    echo "Rust"
elif [[ -f "$path/package.json" ]]; then
    echo "Node.js"
    if command -v jq &>/dev/null && [[ -f "$path/package.json" ]]; then
        scripts=$(jq -r '.scripts | keys | join(", ")' "$path/package.json" 2>/dev/null | head -c 60)
        [[ -n "$scripts" ]] && echo "Scripts: $scripts"
    fi
elif [[ -f "$path/go.mod" ]]; then
    echo "Go"
elif [[ -f "$path/pyproject.toml" ]]; then
    echo "Python (pyproject)"
elif [[ -f "$path/requirements.txt" ]]; then
    echo "Python"
else
    echo "Unknown"
fi
echo ""

# README preview
for readme in README.md readme.md README.rst README; do
    if [[ -f "$path/$readme" ]]; then
        echo "━━━ README ━━━"
        if command -v bat &>/dev/null; then
            bat --style=plain --color=always --line-range=:15 "$path/$readme" 2>/dev/null
        else
            head -15 "$path/$readme"
        fi
        break
    fi
done
