#!/usr/bin/env zsh
# tmux-note-sync.sh - Sync tmux window names to branch note sections
# Called by tmux hooks (after-new-window, window-renamed) via run-shell -b
# Never auto-creates notes — only appends to existing ones.

source "$HOME/.bin/tmux-lib.sh"

NOTES_DIR="$HOME/projects/personal-notes/branch-notes"

# Get active pane path from current session
pane_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -z "$pane_path" ]] && exit 0

# Resolve repo/branch
resolve_note_context "$pane_path" || exit 0

# Check if note exists — if not, exit silently (don't auto-create)
note_file="$NOTES_DIR/$NOTE_REPO/$NOTE_BRANCH/note.md"
[[ -f "$note_file" ]] || exit 0

# Get current windows and append missing sections
tmux list-windows -F '#{window_name}' 2>/dev/null | while IFS= read -r win; do
    if ! grep -Fq "### $win" "$note_file" 2>/dev/null; then
        echo "" >> "$note_file"
        echo "### $win" >> "$note_file"
    fi
done
