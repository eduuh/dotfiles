# regular-repos.zsh — single source of truth for which repos are cloned FLAT
# (regular ~/projects/<name>) instead of bare + worktree.
#
# Sourced by both the install bootstrap (.bin/setup/common.sh) and the worktree
# manager (.bin/wt) so the two never disagree. Everything NOT listed here is
# cloned bare with a default-branch worktree under ~/projects/{bare,worktree}.
#
# Rule of thumb: tools/config you don't branch-develop are flat; project repos
# where you do feature-branch work are bare+worktree.

# nvim is intentionally NOT here: its config is branch-developed (main/shellcmd),
# so it clones bare + worktree like project repos, with ~/.config/nvim → its main
# worktree. See _setup_nvim_config in common.sh.
REGULAR_CLONE_REPOS=(
    dotfiles
    personal-notes
    eduuh
    notes
    bn
)
