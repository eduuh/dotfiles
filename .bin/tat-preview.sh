#!/usr/bin/env zsh
# tat-preview.sh - fzf preview for project selection

# Ensure PATH includes common locations
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

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

    # Status summary using zsh
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
print -n "Type: "
if [[ -f "$path/Cargo.toml" ]]; then
    echo "Rust"
elif [[ -f "$path/package.json" ]]; then
    echo "Node.js"
    if command -v jq &>/dev/null && [[ -f "$path/package.json" ]]; then
        scripts=$(jq -r '.scripts | keys | join(", ")' "$path/package.json" 2>/dev/null)
        [[ -n "$scripts" ]] && echo "Scripts: ${scripts:0:60}"
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
            # Use zsh to read first 15 lines
            local i=0
            while IFS= read -r line && (( i++ < 15 )); do
                echo "$line"
            done < "$path/$readme"
        fi
        break
    fi
done
