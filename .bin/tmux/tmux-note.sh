#!/usr/bin/env zsh
# tmux-note.sh - Open the current branch's note in a tmux popup.
# The caller's -d has already set cwd, so `bn` resolves relative to it.

# Resolve / create the note for this git context
note_dir=$("$HOME/.bin/bn" 2>/dev/null)
if [[ -z "$note_dir" || ! -d "$note_dir" ]]; then
    echo "bn: could not resolve branch note dir for $(pwd)"
    echo "    Make sure you're inside a git repo."
    read -sk1 "?Press any key..."
    exit 1
fi
note_file="${note_dir}/note.md"

# Sync tmux window-name sections into the note (preserves existing behaviour)
tmux list-windows -F '#{window_name}' 2>/dev/null | while IFS= read -r win; do
    if ! grep -Fq "### $win" "$note_file" 2>/dev/null; then
        printf '\n### %s\n' "$win" >> "$note_file"
    fi
done

exec nvim "$note_file"
