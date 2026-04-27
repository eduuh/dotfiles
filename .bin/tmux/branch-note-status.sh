#!/usr/bin/env zsh
# branch-note-status.sh - Todo count for tmux status bar
# Output e.g. " [3]" if there are open todos, nothing otherwise.
# Called every status-interval (5s) — must be fast and silent on failure.

source "$HOME/.bin/tmux/tmux-lib.sh"

resolve_note_context "${1:-$(pwd)}" || exit 0

note_dir="$HOME/projects/worktree/personal-notes/branch-notes/branch-notes/$NOTE_REPO/$NOTE_BRANCH"
note="$note_dir/note.md"
yaml="$note_dir/note.yaml"
[[ -f "$note" ]] || exit 0

if [[ -f "$yaml" ]]; then
    note_status=$(yq -r '.status // "active"' "$yaml" 2>/dev/null)
    [[ "$note_status" == "closed" ]] && exit 0
    count=$(yq -r '[.todos[] | select(.done != true)] | length' "$yaml" 2>/dev/null)
else
    note_status=$(sed -n '/^---$/,/^---$/{ /^status:/s/^status: *//p; }' "$note")
    [[ "$note_status" == "closed" ]] && exit 0
    count=$(grep -c '^\- \[ \]' "$note" 2>/dev/null)
fi

(( count > 0 )) && echo " TODO[$count]"
