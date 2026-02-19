#!/usr/bin/env zsh
# branch-note.sh - Universal branch note resolver
# Usage:
#   branch-note                          # Ensure note exists, print dir path
#   branch-note --path                   # Print note dir path only (no create)
#   branch-note --cat [file]             # Print note.md contents (or specific file)
#   branch-note --edit [file]            # Open note.md in $EDITOR (or specific file)
#   branch-note add <section> <text>     # Add line to section
#   branch-note list [--all]             # List active notes (--all includes closed)
#   branch-note active                   # List active notes
#   branch-note close                    # Close current branch's note
#   branch-note prune                    # Close notes whose worktrees no longer exist
#   branch-note summary                  # Dashboard: open todos, blockers, per-branch detail
#   branch-note refresh                  # Fetch, pull, build current branch
#   branch-note refresh-all              # Refresh all main worktrees
#   branch-note build-init               # Create build.sh for current repo
#   branch-note build-edit               # Open build.sh in $EDITOR

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
status: active
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

# Read status from frontmatter (defaults to "active" if missing)
get_note_status() {
    local note_file="$1"
    local status
    status=$(sed -n '/^---$/,/^---$/{ /^status:/s/^status: *//p; }' "$note_file")
    echo "${status:-active}"
}

# Set status in frontmatter
set_note_status() {
    local note_file="$1" new_status="$2"
    if grep -q '^status:' "$note_file"; then
        sed -i '' "s/^status: .*/status: $new_status/" "$note_file"
    else
        # Insert status after created line
        sed -i '' "/^created:/a\\
status: $new_status" "$note_file"
    fi
}

# Resolve path to build.sh (always in main's note dir)
resolve_build_sh() {
    local repo="$1"
    echo "$NOTES_DIR/$repo/main/build.sh"
}

# Run build.sh if it exists, with cwd set to given directory
run_build_sh() {
    local repo="$1" work_dir="$2"
    local build_sh
    build_sh=$(resolve_build_sh "$repo")
    if [[ -x "$build_sh" ]]; then
        echo "Running build.sh for $repo..."
        (cd "$work_dir" && "$build_sh")
        return $?
    fi
    return 0
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

# List notes across repos (active only by default)
cmd_list() {
    local show_all=false
    [[ "$1" == "--all" ]] && show_all=true

    [[ ! -d "$NOTES_DIR" ]] && { echo "No branch notes found"; exit 0; }

    local found=false
    for note_file in "$NOTES_DIR"/*/*/note.md(N); do
        local status=$(get_note_status "$note_file")
        if ! $show_all && [[ "$status" == "closed" ]]; then
            continue
        fi

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

        local status_tag=""
        [[ "$status" == "closed" ]] && status_tag=" (closed)"

        printf "%-30s %-12s %d todos  %s%s\n" "$repo/$branch" "$type" "$todos" "$created" "$status_tag"
    done

    $found || echo "No branch notes found"
}

# Close current branch's note
cmd_close() {
    resolve_note_context "$(pwd)" || { echo "Not in a git repo" >&2; exit 1; }
    local note_file="$NOTES_DIR/$NOTE_REPO/$NOTE_BRANCH/note.md"
    [[ ! -f "$note_file" ]] && { echo "No note for $NOTE_REPO/$NOTE_BRANCH" >&2; exit 1; }

    set_note_status "$note_file" "closed"
    echo "Closed note: $NOTE_REPO/$NOTE_BRANCH"
}

# Close notes whose worktrees no longer exist
cmd_prune() {
    [[ ! -d "$NOTES_DIR" ]] && { echo "No branch notes found"; exit 0; }

    local closed=0
    for note_file in "$NOTES_DIR"/*/*/note.md(N); do
        local status=$(get_note_status "$note_file")
        [[ "$status" == "closed" ]] && continue

        local note_dir=$(dirname "$note_file")
        local branch=$(basename "$note_dir")
        local repo=$(basename "$(dirname "$note_dir")")

        # Only prune worktree-based repos (those with a bare repo)
        [[ ! -d "$BARE_DIR/${repo}.git" ]] && continue

        local worktree_path="$WORKTREE_DIR/${repo}/${branch}"
        if [[ ! -d "$worktree_path" ]]; then
            set_note_status "$note_file" "closed"
            echo "Closed: $repo/$branch (worktree removed)"
            closed=$((closed + 1))
        fi
    done

    (( closed == 0 )) && echo "Nothing to prune"
}

# Summary dashboard
cmd_summary() {
    [[ ! -d "$NOTES_DIR" ]] && { echo "No branch notes found"; exit 0; }

    local total_todos=0
    local total_blockers=0
    local details=""
    local found=false

    for note_file in "$NOTES_DIR"/*/*/note.md(N); do
        local status=$(get_note_status "$note_file")
        [[ "$status" == "closed" ]] && continue

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

# Refresh current branch: fetch, pull, build
cmd_refresh() {
    resolve_note_context "$(pwd)" || { echo "Not in a git repo" >&2; exit 1; }

    local bare_repo="$BARE_DIR/${NOTE_REPO}.git"
    local worktree_path
    worktree_path=$(pwd)

    if [[ -d "$bare_repo" ]]; then
        echo "Fetching origin for $NOTE_REPO..."
        git --git-dir="$bare_repo" fetch origin

        echo "Pulling $NOTE_BRANCH (ff-only)..."
        git -C "$worktree_path" pull --ff-only
    else
        # Regular repo (not bare)
        echo "Fetching origin for $NOTE_REPO..."
        git -C "$worktree_path" fetch origin

        echo "Pulling $NOTE_BRANCH (ff-only)..."
        git -C "$worktree_path" pull --ff-only
    fi

    run_build_sh "$NOTE_REPO" "$worktree_path"
    echo "Refresh complete: $NOTE_REPO/$NOTE_BRANCH"
}

# Refresh all main worktrees: parallel fetch, sequential update+build
cmd_refresh_all() {
    local bare_repos=("$BARE_DIR"/*.git(N/))
    [[ ${#bare_repos[@]} -eq 0 ]] && { echo "No bare repos found"; exit 0; }

    local updated=0 skipped=0 failed=0

    # Phase 1: parallel fetch all bare repos
    echo "Fetching all repos..."
    local pids=()
    for bare in "${bare_repos[@]}"; do
        git --git-dir="$bare" fetch origin &
        pids+=($!)
    done
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    echo "Fetch complete."

    # Phase 2: sequential update + build
    for bare in "${bare_repos[@]}"; do
        local repo_name=$(basename "$bare" .git)
        local main_wt="$WORKTREE_DIR/${repo_name}/main"

        if [[ ! -d "$main_wt" ]]; then
            echo "  $repo_name: no main worktree, skipping"
            skipped=$((skipped + 1))
            continue
        fi

        echo "  $repo_name: updating main..."

        # Fast-forward the local main branch ref
        git --git-dir="$bare" branch -f main origin/main 2>/dev/null

        # Pull in the worktree
        if git -C "$main_wt" pull --ff-only 2>/dev/null; then
            if run_build_sh "$repo_name" "$main_wt"; then
                updated=$((updated + 1))
            else
                echo "  $repo_name: build failed"
                failed=$((failed + 1))
            fi
        else
            echo "  $repo_name: pull failed (not fast-forwardable?)"
            failed=$((failed + 1))
        fi
    done

    echo ""
    echo "Summary: $updated updated, $skipped skipped, $failed failed"
}

# Create build.sh template for current repo
cmd_build_init() {
    resolve_note_context "$(pwd)" || { echo "Not in a git repo" >&2; exit 1; }

    local build_sh
    build_sh=$(resolve_build_sh "$NOTE_REPO")

    if [[ -f "$build_sh" ]]; then
        echo "build.sh already exists: $build_sh" >&2
        echo "Use 'bn build-edit' to modify it." >&2
        exit 1
    fi

    mkdir -p "$(dirname "$build_sh")"
    cat > "$build_sh" << 'BUILDEOF'
#!/usr/bin/env zsh
set -e

# Build script for this repo — runs after worktree create and on refresh.
# Uncomment/modify the section that matches your project:

# --- Rust ---
# cargo build

# --- Node ---
# npm install

# --- Go ---
# go build ./...

# --- Make ---
# make

echo "Build complete."
BUILDEOF
    chmod +x "$build_sh"
    echo "Created: $build_sh"
    echo "Edit with: bn build-edit"
}

# Open build.sh in editor
cmd_build_edit() {
    resolve_note_context "$(pwd)" || { echo "Not in a git repo" >&2; exit 1; }

    local build_sh
    build_sh=$(resolve_build_sh "$NOTE_REPO")

    if [[ ! -f "$build_sh" ]]; then
        echo "No build.sh for $NOTE_REPO. Create one with: bn build-init" >&2
        exit 1
    fi

    ${EDITOR:-nvim} "$build_sh"
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
        shift
        cmd_list "$@"
        ;;
    active)
        cmd_list
        ;;
    close)
        cmd_close
        ;;
    prune)
        cmd_prune
        ;;
    summary)
        cmd_summary
        ;;
    refresh)
        cmd_refresh
        ;;
    refresh-all)
        cmd_refresh_all
        ;;
    build-init)
        cmd_build_init
        ;;
    build-edit)
        cmd_build_edit
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
  list [--all]                    List active notes (--all includes closed)
  active                          List active notes (same as list)
  close                           Close current branch's note
  prune                           Close notes whose worktrees are gone
  summary                         Dashboard of active work
  refresh                          Fetch, pull, build current branch
  refresh-all                      Refresh all main worktrees
  build-init                       Create build.sh template for repo
  build-edit                       Open build.sh in \$EDITOR

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
