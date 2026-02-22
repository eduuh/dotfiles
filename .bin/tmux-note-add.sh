#!/usr/bin/env zsh
# tmux-note-add.sh - Quick-add to branch note via fzf section picker
# Called via: bind N display-popup -E ... "$HOME/.bin/tmux-note-add.sh '#{pane_current_path}'"

source "$HOME/.bin/tmux-lib.sh"
require_fzf

# cd to pane path so branch-note.sh subcommands resolve correctly
pane_path="${1:-$(pwd)}"
cd "$pane_path" 2>/dev/null || { echo "Invalid path: $pane_path"; read -sk1; exit 1; }
resolve_note_context "$pane_path" || { echo "Not in a git repo"; read -sk1; exit 1; }

# Ensure note exists
"$HOME/.bin/bn" >/dev/null

# fzf section picker
section=$(printf "Todos\nBlockers\nDecisions\nTo Research\nCollaboration\nTo Ask" | $FZF_CMD --prompt="Section: " --height=8 --reverse)
[[ -z "$section" ]] && exit 0

# Map display name to add command name
case "$section" in
    Todos)         cmd_section="todo" ;;
    Blockers)      cmd_section="blocker" ;;
    Decisions)     cmd_section="decision" ;;
    "To Research") cmd_section="research" ;;
    Collaboration) cmd_section="collab" ;;
    "To Ask")      cmd_section="ask" ;;
esac

# Prompt for text
window_name=$(tmux display-message -p '#{window_name}' 2>/dev/null)
printf "> "
read -r "input"
[[ -z "$input" ]] && exit 0

# Add context tag and insert
[[ -n "$window_name" ]] && input="$input *($window_name)*"
"$HOME/.bin/bn" add "$cmd_section" "$input"
