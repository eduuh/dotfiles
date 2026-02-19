#!/usr/bin/env zsh
# tmux-note.sh - Open branch note in tmux popup
# Called via: bind n display-popup -E ... "$HOME/.bin/tmux-note.sh '#{pane_current_path}'"

source "$HOME/.bin/tmux-lib.sh"

NOTES_DIR="$HOME/projects/personal-notes/branch-notes"

# cd to pane path so branch-note.sh subcommands resolve correctly
pane_path="${1:-$(pwd)}"
cd "$pane_path" 2>/dev/null || { echo "Invalid path: $pane_path"; read -sk1; exit 1; }
resolve_note_context "$pane_path" || { echo "Not in a git repo"; read -sk1; exit 1; }

# Ensure note exists (creates from template if needed)
note_dir=$("$HOME/.bin/branch-note.sh")
note_file="$note_dir/note.md"

# Sync window sections
tmux list-windows -F '#{window_name}' 2>/dev/null | while IFS= read -r win; do
    if ! grep -Fq "### $win" "$note_file" 2>/dev/null; then
        echo "" >> "$note_file"
        echo "### $win" >> "$note_file"
    fi
done

# Open in editor
${EDITOR:-nvim} "$note_file"
