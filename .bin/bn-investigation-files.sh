#!/usr/bin/env zsh
# bn-investigation-files.sh - List investigation files for /get-context skill
note_dir=$(bn --path 2>/dev/null) || { echo "No investigation files."; exit 0; }
files=("$note_dir"/*.md(N))
found=false
for f in "${files[@]}"; do
    [[ "$(basename "$f")" == "note.md" ]] && continue
    found=true
    echo "### $(basename "$f")"
    echo '```'
    cat "$f"
    echo '```'
    echo
done
$found || echo "No investigation files."
