[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# User-local tools on PATH for ALL shells, not just interactive ones: bn + its workflow
# scripts live in ~/.bn/bin (bn's self-contained home), fzf/zoxide/nvim in ~/.local/bin,
# legacy helpers in ~/.bin. ~/.bn/bin goes first so the bn there wins over any stale copy.
# Keeping this in .zshenv (not .zshrc) lets non-interactive `zsh -c` — e.g. tmux popups —
# resolve them without paying the full interactive-shell startup cost.
export PATH="$HOME/.bn/bin:$HOME/.bin:$HOME/.local/bin:$PATH"
