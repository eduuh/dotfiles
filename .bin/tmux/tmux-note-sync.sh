#!/usr/bin/env zsh
# tmux-note-sync.sh - Sync current window name to its own branch note
# Called by tmux hooks (after-new-window, window-renamed) via run-shell -b
# Never auto-creates notes — only appends to existing ones.

source "$HOME/.bin/tmux/tmux-lib.sh"
tmux_init

NOTES_DIR="$HOME/projects/worktree/personal-notes/branch-notes/branch-notes"

# Get current window's pane path
pane_path=$($TMUX_CMD display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -z "$pane_path" ]] && exit 0

# Resolve repo/branch
resolve_note_context "$pane_path" || exit 0

# Check if note exists — if not, exit silently (don't auto-create)
note_file="$NOTES_DIR/$NOTE_REPO/$NOTE_BRANCH/note.md"
[[ -f "$note_file" ]] || exit 0

# Only add this window's own section to its own note
win_name=$($TMUX_CMD display-message -p '#{window_name}' 2>/dev/null)
[[ -z "$win_name" ]] && exit 0

if ! grep -Fq "### $win_name" "$note_file" 2>/dev/null; then
    echo "" >> "$note_file"
    echo "### $win_name" >> "$note_file"
fi
