# Setup fzf
# ---------
# Prefer a user-local fzf (e.g. ~/.local/bin) over an older system one so the
# shell-integration flag (`fzf --zsh`, added in fzf 0.48) is available.
if [[ -d "$HOME/.local/bin" && ! "$PATH" == *"$HOME/.local/bin"* ]]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# Only load integration if the resolved fzf supports `--zsh`; older builds
# (e.g. Debian 0.44) print "unknown option: --zsh" on every new shell.
if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
