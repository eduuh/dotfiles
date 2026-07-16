# Setup fzf
# ---------
# Prefer a user-local fzf (e.g. ~/.local/bin) over an older system one so the
# shell-integration flag (`fzf --bash`, added in fzf 0.48) is available.
if [[ -d "$HOME/.local/bin" && ! "$PATH" == *"$HOME/.local/bin"* ]]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# Only load integration if the resolved fzf supports `--bash`; older builds
# (e.g. Debian 0.44) print "unknown option: --bash" on every new shell.
if command -v fzf >/dev/null 2>&1 && fzf --bash >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi
