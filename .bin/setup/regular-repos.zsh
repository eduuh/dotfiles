# regular-repos.zsh — single source of truth for which repos are cloned FLAT
# (regular ~/projects/<name>) instead of bare + worktree.
#
# Sourced by both the install bootstrap (.bin/setup/common.sh) and the worktree
# manager (.bin/wt) so the two never disagree. Everything NOT listed here is
# cloned bare with a default-branch worktree under ~/projects/{bare,worktree}.
#
# Rule of thumb: tools/config you don't branch-develop are flat; project repos
# where you do feature-branch work are bare+worktree.

# nvim, dotfiles, and bn are intentionally NOT here: they're branch-developed (feature
# branches, PRs), so they clone bare + worktree like project repos. dotfiles is stowed
# from its main worktree (~/projects/worktree/dotfiles/main); nvim links ~/.config/nvim →
# its main worktree. See _setup_nvim_config in common.sh.
REGULAR_CLONE_REPOS=(
    personal-notes
    eduuh
    notes
    # bn's notes store. Flat, and never branch-developed: bn commits to its main
    # from every machine, so a worktree layout would only get in the way.
    branch-notes
    # Windows applications: built and run from the Windows side, so they are
    # cloned flat and — via WINDOWS_CLONE_REPOS — onto the Windows filesystem.
    # They must be listed HERE too: only a regular clone consults the Windows
    # routing, so a repo in WINDOWS_CLONE_REPOS alone still lands bare+worktree
    # inside WSL, where Windows tooling can't reach it.
    win-dot
    keyflow
)
