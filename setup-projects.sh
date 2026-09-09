#!/bin/zsh
# Standalone script to clone project repositories (parallel).
# Run this after setup.sh has configured the machine.
#
#   ./setup-projects.sh [--work] [--personal]
#
# --work     also clones the work repos     (personal-notes/scripts/setup-work-repos.sh)
# --personal also clones the personal repos (personal-notes/scripts/setup-personal-repos.sh)
# setup.sh passes both through when it was itself invoked with them.

# ${0:A:h}, not ${BASH_SOURCE[0]}: these are zsh scripts and BASH_SOURCE is a bash-ism
# that expands to nothing under zsh, so SCRIPT_DIR silently became the CALLER's cwd —
# sourcing common.sh only worked when you happened to run this from the repo root.
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/.bin/setup/common.sh"

SETUP_WORK=false
SETUP_PERSONAL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --work)     SETUP_WORK=true; shift ;;
        --personal) SETUP_PERSONAL=true; shift ;;
        *)          shift ;;
    esac
done

# personal-notes FIRST and on its own: every work/personal repo list, and the stow
# tree below, lives inside it. Running it here as well as in setup.sh keeps this
# script standalone — it's a no-op pull when setup.sh already did it.
ensure_personal_notes

clone_repos
setup_personal_notes_stow
setup_git_hooks

# Record the step so a later `setup.sh` skips relaunching the clone. setup.sh runs this
# detached (tmux/nohup) and never waits, so the marker is written here on completion.
#
# Only on a clean run: marking a run with failed clones as done would skip the
# whole step forever, leaving those repos permanently missing with no retry.
if (( ${#SETUP_FAILURES[@]} == 0 )); then
    _projects_mark_done
else
    print_failure_summary
    echo "· 'projects' not marked done — re-run ./setup-projects.sh to retry the above."
    exit 1
fi
