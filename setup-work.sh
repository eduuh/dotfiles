#!/bin/zsh
# Clone work repositories. The list of work repos is intentionally kept
# outside this public dotfiles repo — point this at a private script that
# defines the URLs and calls `_clone_single_repo` for each.
#
# Default location:  ~/.config/dotfiles/clone-work.sh
# Override:          WORK_CLONE_SCRIPT=/some/path ./setup-work.sh
#
# Repos cloned this way that are NOT in REGULAR_CLONE_REPOS (in common.sh)
# land in ~/projects/bare/<name>.git with an initial worktree at
# ~/projects/worktree/<name>/<default-branch>, so `wt` and `tat` pick them up
# naturally.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.bin/setup/common.sh"

WORK_CLONE_SCRIPT="${WORK_CLONE_SCRIPT:-$HOME/.config/dotfiles/clone-work.sh}"

if [[ ! -f "$WORK_CLONE_SCRIPT" ]]; then
    cat <<EOF
No work clone script found at: $WORK_CLONE_SCRIPT

To set one up, clone your private work-config repo there. Example:

    mkdir -p ~/.config/dotfiles
    git clone git@github.com:edwinmuraya-microsoft/dotfiles-work.git ~/.config/dotfiles

The script should define a list of repo URLs and clone each one, e.g.:

    WORK_REPOS=(
        "git@github.com:my-org/repo-a.git"
        "git@github.com:my-org/repo-b.git"
    )
    for r in "\${WORK_REPOS[@]}"; do
        _clone_single_repo "\$r" &
    done
    wait

EOF
    exit 1
fi

mkdir -p ~/projects ~/projects/bare ~/projects/worktree
echo "Sourcing work clone script: $WORK_CLONE_SCRIPT"
source "$WORK_CLONE_SCRIPT"
echo "Work repo clones finished."
