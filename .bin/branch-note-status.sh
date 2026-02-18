#!/usr/bin/env zsh
# branch-note-status.sh - Todo count for tmux status bar
# Output e.g. " [3]" if there are open todos, nothing otherwise.
# Called every status-interval (5s) — must be fast and silent on failure.

source "$HOME/.bin/tmux-lib.sh"

resolve_note_context "${1:-$(pwd)}" || exit 0

note="$HOME/projects/personal-notes/branch-notes/$NOTE_REPO/$NOTE_BRANCH/note.md"
[[ -f "$note" ]] || exit 0

count=$(grep -c '^\- \[ \]' "$note" 2>/dev/null)
(( count > 0 )) && echo " [$count]"
