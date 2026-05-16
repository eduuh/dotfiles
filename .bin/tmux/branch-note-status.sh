#!/usr/bin/env zsh
# branch-note-status.sh - Todo count for tmux status bar
# Output e.g. " [3]" if there are open todos, nothing otherwise.
# Called every status-interval (5s) — must be fast and silent on failure.

source "$HOME/.bin/tmux/tmux-lib.sh"

resolve_note_context "${1:-$(pwd)}" || exit 0

# Match bn's WORK_REPOS allowlist so the status badge reads from the right repo.
work_repos_file="${BN_WORK_REPOS_FILE:-$HOME/.config/bn/work-repos}"
notes_dir="$HOME/projects/branch-notes"
if [[ -r "$work_repos_file" ]]; then
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line//[[:space:]]/}"
        [[ "$line" == "$NOTE_REPO" ]] && { notes_dir="$HOME/projects/branch-notes-work"; break; }
    done < "$work_repos_file"
fi

note_dir="$notes_dir/$NOTE_REPO/$NOTE_BRANCH"
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
