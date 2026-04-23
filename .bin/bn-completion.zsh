#compdef bn

# Completion for bn (branch notes manager)

_bn_sections=(todo blocker decision research collab ask)

_bn() {
    local -a commands=(
        '--path:Print note dir path'
        '-p:Print note dir path'
        '--cat:Print note contents'
        '-c:Print note contents'
        '--edit:Open note in editor'
        '-e:Open note in editor'
        'add:Add line to section'
        'a:Add line to section'
        'list:List active notes'
        'l:List active notes'
        'active:List active notes'
        'close:Close current branch note'
        'reopen:Reopen a closed note'
        'done:Mark a todo as done by id or substring'
        'prune:Close notes for removed worktrees'
        'summary:Dashboard of active work'
        's:Dashboard of active work'
        'status:One-line status for current branch'
        'st:One-line status for current branch'
        'brief:Lean SessionStart view (goal + open items + recent)'
        '--json:Dump note.yaml as JSON'
        'json:Dump note.yaml as JSON'
        'migrate:Convert md-only notes to split md + yaml'
        'log-progress:Append a timestamped line to Progress'
        'todo:List open todos across all branches'
        'todos:List open todos across all branches'
        't:Add todo or list todos'
        'research:Add research item or list research'
        'r:Add research item or list research'
        'refresh:Fetch, pull, build current branch'
        'rf:Fetch, pull, build current branch'
        'refresh-all:Refresh all main worktrees'
        'ra:Refresh all main worktrees'
        'main:Print main note dir + list scripts'
        'm:Print main note dir + list scripts'
        'blocker:Add blocker or list blockers'
        'x:Add blocker or list blockers'
        'search:Search across all active notes'
        'stale:Show notes not modified recently'
        'build:Run a script'
        'b:Run a script'
        'script:Manage repo scripts'
        'sc:Manage repo scripts'
        'archive:Archive old closed notes'
        'clean:Remove empty placeholder todos'
        'files:Investigation file management'
        'f:Investigation file management'
        'worktrees:All active worktrees with details'
        'w:All active worktrees with details'
        'pr:Link or open PR'
        'link:Link work item'
        'wi:Link work item'
        'review:PR review management'
        'rv:PR review management'
        'diff:Git diff stat + open todos'
        'd:Git diff stat + open todos'
        'achieve:Log an achievement'
        'ac:Log an achievement'
        'global:Repo-level global note'
        'g:Repo-level global note'
        'help:Show help'
    )

    if (( CURRENT == 2 )); then
        _describe -t commands 'bn command' commands
        return
    fi

    case "${words[2]}" in
        add|a)
            if (( CURRENT == 3 )); then
                _describe -t sections 'section' \
                    '(todo blocker decision research collab ask)'
            fi
            ;;
        script|sc)
            if (( CURRENT == 3 )); then
                local -a script_cmds=(
                    'new:Create a new script'
                    'edit:Open script in editor'
                    'list:List scripts'
                    'l:List scripts'
                )
                _describe -t script-cmds 'script command' script_cmds
            fi
            ;;
        files|f)
            if (( CURRENT == 3 )); then
                local -a file_cmds=(
                    'new:Create new investigation file'
                    'edit:Open investigation file in editor'
                )
                # Also complete existing investigation files
                local note_dir
                note_dir=$(bn --path 2>/dev/null)
                if [[ -n "$note_dir" && -d "$note_dir" ]]; then
                    local -a inv_files
                    for f in "$note_dir"/*.md(N); do
                        [[ "${f:t}" == "note.md" ]] && continue
                        inv_files+=("${${f:t}%.md}:Investigation file")
                    done
                    _describe -t files 'file' file_cmds -- inv_files
                else
                    _describe -t files 'file command' file_cmds
                fi
            fi
            ;;
        review|rv)
            if (( CURRENT == 3 )); then
                local -a review_cmds=(
                    'new:Create new PR review'
                    'edit:Open PR review in editor'
                )
                _describe -t review-cmds 'review command' review_cmds
            fi
            ;;
        build|b)
            if (( CURRENT == 3 )); then
                local scripts_dir
                scripts_dir=$(bn --path 2>/dev/null)
                scripts_dir="${scripts_dir%/*}/main/scripts"
                if [[ -d "$scripts_dir" ]]; then
                    local -a scripts
                    for f in "$scripts_dir"/*(N:t); do
                        scripts+=("$f:Script")
                    done
                    _describe -t scripts 'script' scripts
                fi
            fi
            ;;
        list|l)
            _arguments '--all[Include closed notes]' '--all-machines[Show notes from all hosts]'
            ;;
        done)
            if (( CURRENT == 3 )); then
                local -a todos
                local json
                json=$(bn --json 2>/dev/null)
                if [[ -n "$json" ]]; then
                    while IFS=$'\t' read -r tid text; do
                        [[ -n "$tid" ]] && todos+=("${tid}:${text}")
                    done < <(echo "$json" | jq -r '.todos[]? | select(.done != true) | "\(.id)\t\(.text)"' 2>/dev/null)
                    (( ${#todos[@]} > 0 )) && _describe -t todos 'open todo' todos
                fi
            fi
            ;;
        migrate)
            _arguments '--dry-run[Show what would migrate without writing]'
            ;;
        archive)
            _arguments '--days[Days threshold]:days:' '--dry-run[Show what would be archived]'
            ;;
        clean)
            _arguments '--all[Clean all notes]'
            ;;
        pr)
            _arguments '--copy[Copy PR URL to clipboard]' '--show[Print PR URL]'
            ;;
        link|wi)
            _arguments '--copy[Copy work item URL to clipboard]' '--show[Print work item URL]'
            ;;
        achieve|ac)
            _arguments '--list[Print achievements]' '--edit[Open achievements in editor]' '--path[Print achievements path]'
            ;;
        stale)
            _arguments '--days[Days threshold]:days:'
            ;;
        global|g)
            if (( CURRENT == 3 )); then
                local -a global_cmds=(
                    '--cat:Print global note'
                    '--edit:Open global note in editor'
                    '--path:Print global note path'
                    'add:Add to global note'
                )
                _describe -t global-cmds 'global command' global_cmds
            fi
            ;;
    esac
}

_bn "$@"
