#!/usr/bin/env zsh
# Zsh completion for bn (branch notes)

_bn() {
    local -a commands sections

    commands=(
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
        'prune:Close notes for removed worktrees'
        'summary:Dashboard of active work'
        's:Dashboard of active work'
        'status:One-line status for current branch'
        'st:One-line status for current branch'
        'todo:List open todos across all branches'
        't:List open todos'
        'refresh:Fetch, pull, build current branch'
        'r:Fetch, pull, build'
        'refresh-all:Refresh all main worktrees'
        'ra:Refresh all main worktrees'
        'main:Print main note dir + list scripts'
        'm:Print main note dir'
        'build:Run a script'
        'b:Run a script'
        'script:Manage repo scripts'
        'sc:Manage repo scripts'
        'files:Investigation file management'
        'f:Investigation files'
        'archive:Archive old closed notes'
        'clean:Remove empty placeholder todos'
        'worktrees:All active worktrees with details'
        'w:All active worktrees'
        'pr:Link or open PR'
        'link:Link or open work item'
        'wi:Link or open work item'
        'diff:Git diff stat + open todos'
        'd:Git diff stat + open todos'
        'global:Repo-level global note'
        'g:Repo-level global note'
        'help:Show help'
    )

    sections=(
        'todo:Add a todo item'
        'blocker:Add a blocker'
        'decision:Add a decision'
        'research:Add a research item'
        'collab:Add a collaboration note'
        'ask:Add a question'
    )

    if (( CURRENT == 2 )); then
        _describe 'command' commands
        return
    fi

    case "${words[2]}" in
        add|a)
            if (( CURRENT == 3 )); then
                _describe 'section' sections
            fi
            ;;
        --cat|-c|--edit|-e|files|f)
            if (( CURRENT == 3 )); then
                # Complete investigation file names
                local note_dir
                note_dir=$("$HOME/.bin/bn" --path 2>/dev/null)
                if [[ -n "$note_dir" && -d "$note_dir" ]]; then
                    local -a files
                    for f in "$note_dir"/*.md(N); do
                        [[ "${f:t}" == "note.md" ]] && continue
                        files+=("${f:t}")
                    done
                    (( ${#files[@]} > 0 )) && compadd -a files
                fi
                # Subcommands for files
                if [[ "${words[2]}" == (files|f) ]]; then
                    local -a file_cmds=('new:Create new investigation file' 'edit:Edit investigation file')
                    _describe 'subcommand' file_cmds
                fi
            fi
            ;;
        build|b)
            if (( CURRENT == 3 )); then
                local scripts_dir
                scripts_dir=$("$HOME/.bin/bn" --path 2>/dev/null)
                scripts_dir="${scripts_dir%/*/*}/main/scripts"
                if [[ -d "$scripts_dir" ]]; then
                    local -a scripts
                    for f in "$scripts_dir"/*(Nx); do
                        scripts+=("${f:t}")
                    done
                    (( ${#scripts[@]} > 0 )) && compadd -a scripts
                fi
            fi
            ;;
        script|sc)
            if (( CURRENT == 3 )); then
                local -a subcmds=('new:Create new script' 'edit:Edit script' 'list:List scripts')
                _describe 'subcommand' subcmds
            fi
            ;;
        pr)
            _arguments '--copy[Copy URL to clipboard]' '--show[Print URL without opening]'
            ;;
        link|wi)
            _arguments '--copy[Copy URL to clipboard]' '--show[Print URL without opening]'
            ;;
        list|l)
            _arguments '--all[Include closed notes]' '--all-machines[Show all machines]'
            ;;
        global|g)
            if (( CURRENT == 3 )); then
                local -a gcmds=('--cat:Print global note' '--edit:Edit global note' '--path:Print path' 'add:Add to global note')
                _describe 'subcommand' gcmds
            fi
            ;;
    esac
}

(( $+functions[compdef] )) && compdef _bn bn
