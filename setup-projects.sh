#!/bin/zsh
# Standalone script to clone project repositories (parallel).
# Run this after setup.sh has configured the machine.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.bin/setup/common.sh"

clone_repos
setup_personal_notes_stow
setup_git_hooks

# Record the step so a later `setup.sh` skips relaunching the clone. setup.sh runs this
# detached (tmux/nohup) and never waits, so the marker is written here on completion.
_step_mark_done projects
