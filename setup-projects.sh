#!/bin/zsh
# Standalone script to clone project repositories (parallel).
# Run this after setup.sh has configured the machine.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.bin/setup/common.sh"

clone_repos
setup_git_hooks
