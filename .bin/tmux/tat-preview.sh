#!/usr/bin/env zsh
# tat-preview.sh - fzf preview for project selection

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init

project="$1"
if is_bare_repo "$project"; then
    path=$(bare_repo_main_path "$project")
else
    path=$(resolve_project_path "$project")
fi

[[ ! -d "$path" ]] && { echo "Directory not found: $path"; exit 1; }

# Header
echo "━━━ $project ━━━"
echo ""

# Session windows (active sessions only)
if $TMUX_CMD has-session -t "=$project" 2>/dev/null; then
    echo "Windows:"
    $TMUX_CMD list-windows -t "=$project" \
        -F "#{window_index}|#{window_name}|#{pane_current_command}|#{pane_current_path}|#{window_active}" \
        2>/dev/null | while IFS='|' read -r idx name cmd wpath active; do
        short="${wpath/#$HOME/~}"
        marker=""
        [[ "$active" == "1" ]] && marker="*"
        printf "  %s%s: %-14s %-8s %s\n" "$idx" "$marker" "$name" "$cmd" "$short"
    done
    echo ""
fi

# Git info (handles regular repos and worktrees)
if [[ -d "$path/.git" ]] || [[ -f "$path/.git" ]]; then
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

# Worktrees (bare repos only)
if is_bare_repo "$project"; then
    worktrees=(${(f)"$(list_worktrees "$project")"})
    if (( ${#worktrees[@]} > 0 )); then
        echo "Worktrees: (${#worktrees[@]})"
        for wt in "${worktrees[@]}"; do
            [[ -z "$wt" ]] && continue
            echo "  $wt"
        done
        echo ""
    fi
fi

# Project type detection
project_type=$(detect_project_type "$path")
echo "Type: $(project_type_display "$project_type")"
