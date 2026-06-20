[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# User-local tools on PATH for ALL shells, not just interactive ones: fzf/zoxide/nvim
# live in ~/.local/bin, bn + workflow scripts in ~/.bin. Keeping this in .zshenv (not
# .zshrc) lets non-interactive `zsh -c` — e.g. tmux popups — resolve them without paying
# the full interactive-shell startup cost.
export PATH="$HOME/.bin:$HOME/.local/bin:$PATH"
