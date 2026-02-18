#!/usr/bin/env zsh
# branch-note.sh - Universal branch note resolver
# Usage:
#   branch-note                          # Ensure note exists, print dir path
#   branch-note --path                   # Print note dir path only (no create)
#   branch-note --cat [file]             # Print note.md contents (or specific file)
#   branch-note --edit [file]            # Open note.md in $EDITOR (or specific file)
#   branch-note add <section> <text>     # Add line to section
#   branch-note list                     # List all notes across repos
#   branch-note summary                  # Dashboard: open todos, blockers, per-branch detail

source "$HOME/.bin/tmux-lib.sh"

NOTES_DIR="$HOME/projects/personal-notes/branch-notes"

# Create note from template if it doesn't exist
ensure_note() {
    local note_dir="$NOTES_DIR/$NOTE_REPO/$NOTE_BRANCH"
    local note_file="$note_dir/note.md"
    if [[ ! -f "$note_file" ]]; then
        mkdir -p "$note_dir"
        cat > "$note_file" << EOF
---
repo: $NOTE_REPO
branch: $NOTE_BRANCH
created: $(date +%Y-%m-%d)
type:
collaborators: []
---

# $NOTE_REPO / $NOTE_BRANCH

## Goal


## Todos
- [ ]

## Blockers
-

## Decisions
-

## To Research
-

## Collaboration
-

## To Ask
-

---
## Windows
EOF
    fi
}

# Map short section name to heading
section_heading() {
    case "$1" in
        todo|todos)         echo "## Todos" ;;
        blocker|blockers)   echo "## Blockers" ;;
        decision|decisions) echo "## Decisions" ;;
        research)           echo "## To Research" ;;
        collab)             echo "## Collaboration" ;;
        ask)                echo "## To Ask" ;;
        *) echo "" ;;
    esac
}

# Format line based on section type
format_line() {
    local section="$1" text="$2"
    case "$section" in
        todo|todos) echo "- [ ] $text" ;;
        *)          echo "- $text" ;;
    esac
}

# Insert a line into the correct section of a note
insert_into_section() {
    local note_file="$1" heading="$2" line="$3"

    local heading_line
    heading_line=$(grep -n "^${heading}$" "$note_file" | head -1 | cut -d: -f1)
    [[ -z "$heading_line" ]] && { echo "Section '$heading' not found in note" >&2; return 1; }

    local after_heading=$((heading_line + 1))
    local next_heading_rel
    next_heading_rel=$(tail -n +$after_heading "$note_file" | grep -n '^## \|^---$' | head -1 | cut -d: -f1)

    if [[ -n "$next_heading_rel" ]]; then
        local insert_at=$((heading_line + next_heading_rel - 1))
        # Insert blank line + content before the next heading
        perl -i -pe "print \"${line}\n\" if \$. == ${insert_at}" "$note_file"
    else
        echo "$line" >> "$note_file"
    fi
}

# Add a line to a section
cmd_add() {
    local section="$1"
    [[ -z "$section" ]] && { echo "Usage: branch-note add <section> <text>" >&2; exit 1; }
    shift
    local text="$*"
    [[ -z "$text" ]] && { echo "Usage: branch-note add <section> <text>" >&2; exit 1; }

    local heading
    heading=$(section_heading "$section")
    [[ -z "$heading" ]] && { echo "Unknown section: $section (use: todo, blocker, decision, research, collab, ask)" >&2; exit 1; }

    resolve_note_context "$(pwd)" || { echo "Not in a git repo" >&2; exit 1; }
    ensure_note

    local note_file="$NOTES_DIR/$NOTE_REPO/$NOTE_BRANCH/note.md"
    local line
    line=$(format_line "$section" "$text")

    insert_into_section "$note_file" "$heading" "$line"
    echo "Added to ${heading#\#\# }: $text"
}

# List all notes across repos
cmd_list() {
    [[ ! -d "$NOTES_DIR" ]] && { echo "No branch notes found"; exit 0; }

    local found=false
    for note_file in "$NOTES_DIR"/*/*/note.md(N); do
        found=true
        local note_dir=$(dirname "$note_file")
        local branch=$(basename "$note_dir")
        local repo=$(basename "$(dirname "$note_dir")")

        local type=""
        type=$(sed -n '/^---$/,/^---$/{ /^type:/s/^type: *//p; }' "$note_file")
        [[ -z "$type" ]] && type="-"

        local todos=0
        todos=$(grep -c '^\- \[ \]' "$note_file" 2>/dev/null || true)

        local created=""
        created=$(sed -n '/^---$/,/^---$/{ /^created:/s/^created: *//p; }' "$note_file")

        printf "%-30s %-12s %d todos  %s\n" "$repo/$branch" "$type" "$todos" "$created"
    done

    $found || echo "No branch notes found"
}

# Summary dashboard
cmd_summary() {
    [[ ! -d "$NOTES_DIR" ]] && { echo "No branch notes found"; exit 0; }

    local total_todos=0
    local total_blockers=0
    local details=""
    local found=false

    for note_file in "$NOTES_DIR"/*/*/note.md(N); do
        found=true
        local note_dir=$(dirname "$note_file")
        local branch=$(basename "$note_dir")
        local repo=$(basename "$(dirname "$note_dir")")

        local type=""
        type=$(sed -n '/^---$/,/^---$/{ /^type:/s/^type: *//p; }' "$note_file")
        [[ -z "$type" ]] && type="-"

        local todos=0
        todos=$(grep -c '^\- \[ \]' "$note_file" 2>/dev/null || true)
        total_todos=$((total_todos + todos))

        # Count non-empty blocker lines
        local blockers=0
        blockers=$(awk '/^## Blockers$/{found=1; next} /^## |^---$/{found=0} found && /^- ./' "$note_file" | wc -l | tr -d ' ')
        total_blockers=$((total_blockers + blockers))

        # Build per-branch detail
        local header="\n$repo/$branch ($type, $todos todos"
        (( blockers > 0 )) && header="$header, $blockers blockers"
        header="$header)"

        local items=""
        # Collect open todos
        while IFS= read -r line; do
            [[ -n "$line" ]] && items="$items\n  ${line#- }"
        done <<< "$(grep '^\- \[ \]' "$note_file" 2>/dev/null)"

        # Collect blockers
        while IFS= read -r line; do
            [[ -n "$line" ]] && items="$items\n  [!] ${line#- }"
        done <<< "$(awk '/^## Blockers$/{found=1; next} /^## |^---$/{found=0} found && /^- ./' "$note_file" 2>/dev/null)"

        if (( todos > 0 )) || (( blockers > 0 )); then
            details="$details$header$items"
        fi
    done

    if $found; then
        echo "Open todos across all branches: $total_todos"
        echo "Blockers: $total_blockers"
        [[ -n "$details" ]] && print "$details"
    else
        echo "No branch notes found"
    fi
}

# Main
case "${1:-}" in
    --path)
        resolve_note_context "$(pwd)" || { echo "Not in a git repo" >&2; exit 1; }
        echo "$NOTES_DIR/$NOTE_REPO/$NOTE_BRANCH"
        ;;
    --cat)
        resolve_note_context "$(pwd)" || { echo "Not in a git repo" >&2; exit 1; }
        local file="${2:-note.md}"
        cat "$NOTES_DIR/$NOTE_REPO/$NOTE_BRANCH/$file"
        ;;
    --edit)
        resolve_note_context "$(pwd)" || { echo "Not in a git repo" >&2; exit 1; }
        ensure_note
        local file="${2:-note.md}"
        ${EDITOR:-nvim} "$NOTES_DIR/$NOTE_REPO/$NOTE_BRANCH/$file"
        ;;
    add)
        shift
        cmd_add "$@"
        ;;
    list)
        cmd_list
        ;;
    summary)
        cmd_summary
        ;;
    -h|--help|help)
        cat << 'HELPEOF'
Usage: branch-note [command]

Commands:
  (none)                          Ensure note exists, print dir path
  --path                          Print note dir path (no create)
  --cat [file]                    Print note.md (or specific file)
  --edit [file]                   Open note in $EDITOR
  add <section> <text>            Add line to section
  list                            List all notes across repos
  summary                         Dashboard of active work

Sections: todo, blocker, decision, research, collab, ask
HELPEOF
        ;;
    "")
        resolve_note_context "$(pwd)" || { echo "Not in a git repo" >&2; exit 1; }
        ensure_note
        echo "$NOTES_DIR/$NOTE_REPO/$NOTE_BRANCH"
        ;;
    *)
        echo "Unknown command: $1" >&2
        exit 1
        ;;
esac
