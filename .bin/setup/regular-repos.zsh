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
)
