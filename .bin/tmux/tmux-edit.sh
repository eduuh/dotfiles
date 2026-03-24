#!/usr/bin/env zsh
# tmux-edit.sh - Open nvim with branch note in a vertical split
# Called via: bind e display-popup -E ... "$HOME/.bin/tmux/tmux-edit.sh"

source "$HOME/.bin/tmux/tmux-lib.sh"

# Resolve branch note path (bn --path prints the note dir)
note_file=$("$HOME/.bin/bn" --path 2>/dev/null)/note.md

if [[ -f "$note_file" ]]; then
    # Open nvim: project files + branch note in a right vsplit
    nvim -c "vsplit $note_file | wincmd h" .
else
    nvim .
fi
