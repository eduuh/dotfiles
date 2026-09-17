# Ubuntu's /etc/zsh/zshrc runs a FULL `compinit` on every interactive shell —
# ~330ms, before any of our config, and entirely wasted because .zshrc runs its
# own cached `compinit -C` a moment later. The file documents this flag itself:
#   "If you don't want compinit called here, place the line
#    skip_global_compinit=1 in your $ZDOTDIR/.zshenv"
# .zshenv is read before /etc/zsh/zshrc, which is what makes this work here.
# Measured: an empty interactive shell went from ~400ms to ~60ms.
skip_global_compinit=1

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# User-local tools on PATH for ALL shells, not just interactive ones: bn + its workflow
# scripts live in ~/.bn/bin (bn's self-contained home), fzf/zoxide/nvim in ~/.local/bin,
# legacy helpers in ~/.bin. ~/.bn/bin goes first so the bn there wins over any stale copy.
# Keeping this in .zshenv (not .zshrc) lets non-interactive `zsh -c` — e.g. tmux popups —
# resolve them without paying the full interactive-shell startup cost.
export PATH="$HOME/.bn/bin:$HOME/.bin:$HOME/.local/bin:$PATH"

# node, for the same reason and by the same rule. nvm only puts node on PATH for
# shells that source nvm.sh, which non-interactive ones don't — so `zsh -c 'node -v'`
# failed, and every cron job, build script and tmux popup needing node had to source
# nvm.sh itself. That is why build.sh carries an nvm block, and why the notes say to
# `source ~/.nvm/nvm.sh` in non-login shells.
#
# Resolving the default version costs a couple of file reads and a directory test —
# cheap enough for a file that runs on EVERY zsh, including scripts. The nvm function
# itself stays out of here; .zshrc loads it on demand for shells that switch
# versions. This only guarantees a node exists.
#
# The alias is frequently NOT a version. `nvm install --lts` — which is exactly what
# setup runs — writes `lts/*` into alias/default, which points at alias/lts/*, which
# points at alias/lts/<codename>, which finally holds the version. Following only the
# first hop left node off PATH entirely on a fresh Linux box: bn's installer reported
# "npx not found", and any MCP server spawned as `npx …` could not start. macOS never
# showed it because node there comes from Homebrew, not nvm.
if [ -z "${NVM_BIN:-}" ] && [ -r "$HOME/.nvm/alias/default" ]; then
  _node_alias=$(<"$HOME/.nvm/alias/default")
  # Bounded: an alias loop must not hang every shell this file runs in.
  _node_hops=0
  while [ -n "$_node_alias" ] && [ "$_node_hops" -lt 5 ]; do
    _node_bin=""
    # The alias may hold a bare version (22.18.0) or a v-prefixed one.
    for _node_try in "$_node_alias" "v$_node_alias"; do
      [ -d "$HOME/.nvm/versions/node/$_node_try/bin" ] && { _node_bin="$HOME/.nvm/versions/node/$_node_try/bin"; break; }
    done
    [ -n "$_node_bin" ] && break
    # Not a version, so it names another alias — follow it.
    [ -r "$HOME/.nvm/alias/$_node_alias" ] || { _node_alias=""; break; }
    _node_alias=$(<"$HOME/.nvm/alias/$_node_alias")
    _node_hops=$((_node_hops + 1))
  done

  # Alias missing, broken, or pointing at a version that is not installed: fall back
  # to the newest installed one, so "node exists" does not hinge on alias bookkeeping.
  if [ -z "$_node_bin" ]; then
    for _node_try in "$HOME"/.nvm/versions/node/*/bin(NnOn); do
      _node_bin="$_node_try"
      break
    done
  fi

  [ -n "$_node_bin" ] && export PATH="$_node_bin:$PATH"
  unset _node_alias _node_hops _node_bin _node_try
fi
