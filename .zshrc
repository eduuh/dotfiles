# Basic Path Setup — ~/.bn/bin (bn's self-contained home) first, then legacy ~/.bin
export PATH="$HOME/.bn/bin:$HOME/.bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Homebrew Setup
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # Add GNU coreutils to PATH
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
    alias kanata-restart="sudo launchctl unload /Library/LaunchDaemons/com.custom.kanata.plist && sudo launchctl load /Library/LaunchDaemons/com.custom.kanata.plist"
    alias kanata-log="cat /tmp/kanata.out /tmp/kanata.err"

elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    # Add GNU coreutils to PATH
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
fi

# Generated completions live here and are AUTOLOADED — zsh reads a `_name` file
# only when that command is first completed. This has to join fpath before
# compinit, which is what builds the autoload index.
_ZSH_COMPDIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-completions"
fpath=("$_ZSH_COMPDIR" $fpath)

# Completion system. Must be initialized before anything that calls `compdef`,
# otherwise every new shell prints "command not found: compdef". Runs after brew
# shellenv so Homebrew's site-functions are already on fpath.
if (( ! $+functions[compdef] )); then
  autoload -Uz compinit
  # Rebuild the dump at most once a day; -C skips the slow security audit and
  # the recompile when the cache is fresh.
  if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(Nmh-24) ]]; then
    compinit -C
  else
    compinit
  fi
fi

# Write a completion script into the autoload dir instead of sourcing it. zsh then
# loads it lazily, on first use, rather than parsing it in every shell.
_zsh_completion_file() {       # _zsh_completion_file <name> <binary> <command...>
  local name=$1 bin=$2; shift 2
  local src dst="$_ZSH_COMPDIR/_$name"
  src=$(command -v "$bin" 2>/dev/null) || return 0
  [[ -n "$src" ]] || return 0
  if [[ ! -s "$dst" || "$src" -nt "$dst" ]]; then
    mkdir -p "$_ZSH_COMPDIR"
    "$@" > "$dst.tmp" 2>/dev/null && mv -f "$dst.tmp" "$dst" || rm -f "$dst.tmp"
  fi
}

# Cache the output of an expensive init command, regenerated only when the
# producing binary is newer — so an upgrade is picked up automatically.
_zsh_cached_init() {           # _zsh_cached_init <name> <binary> <command...>
  local name=$1 bin=$2; shift 2
  local src cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init/$name.zsh"
  src=$(command -v "$bin" 2>/dev/null) || return 0
  [[ -n "$src" ]] || return 0
  if [[ ! -s "$cache" || "$src" -nt "$cache" ]]; then
    mkdir -p "${cache:h}"
    "$@" > "$cache.tmp" 2>/dev/null && mv -f "$cache.tmp" "$cache" || { rm -f "$cache.tmp"; return 0; }
  fi
  source "$cache"
}

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
yolo() { bn note >/dev/null 2>&1; command claude --dangerously-skip-permissions "$@"; }
claude() { bn note >/dev/null 2>&1; command claude "$@"; }
copilot() { bn note >/dev/null 2>&1; git rev-parse --is-inside-work-tree >/dev/null 2>&1 && bn mcp init copilot >/dev/null 2>&1; command copilot --yolo "$@"; }
alias po="$HOME/.bin/pkg-open.sh"
alias nvimd='nvim -c "DiffviewOpen origin/main"'
# Bare `tmux` (no args) always attaches to the persistent 'planning' session
# instead of tmux's default of creating a fresh numbered session.
tmux() {
  if [ $# -eq 0 ]; then
    command tmux attach -t planning 2>/dev/null || \
      command tmux new-session -s planning -c "$HOME/projects/personal-notes"
  else
    command tmux "$@"
  fi
}
alias n8n-up='(cd ~/projects/n8n && make up)'
alias n8n-down='(cd ~/projects/n8n && make down)'
alias n8n-logs='(cd ~/projects/n8n && make logs)'
alias n8n-update='(cd ~/projects/n8n && make update)'

# NVM — deliberately NOT sourced here. `nvm.sh` was 99.97% of interactive startup
# (zprof: nvm_process_parameters → nvm_auto → nvm, 7283ms of 7285ms), because it
# re-resolves and re-applies a node version on every single shell.
#
# node itself is already on PATH from .zshenv, which runs for every zsh including
# non-interactive ones. All that is left to arrange here is the nvm FUNCTION, for
# the shells that actually switch versions.
export NVM_DIR="$HOME/.nvm"

# Real nvm only when invoked. Replaces itself on first call, so the cost is paid
# once per shell that genuinely needs version switching — and never otherwise.
nvm() {
  unfunction nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

# Load Cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Load FZF
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# Load Lazy Load. Path was ~/projects/dotfiles, which stopped existing when this
# repo moved to the bare+worktree layout — so this silently never loaded. ~/ is
# the stow target, which is correct regardless of where the repo lives.
[ -f "$HOME/.zsh_lazy_load" ] && source "$HOME/.zsh_lazy_load"

[ -f "$HOME/.zsh/ws.zsh" ] && source "$HOME/.zsh/ws.zsh"

# pnpm
case "$(uname -s)" in
  Darwin) export PNPM_HOME="$HOME/Library/pnpm" ;;
  *)      export PNPM_HOME="$HOME/.local/share/pnpm" ;;
esac
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# Tmux integration: Update current path for splits/windows
if [ -n "$TMUX" ]; then
  _tmux_refresh_path() {
    tmux refresh-client -S 2>/dev/null
  }
  chpwd_functions+=(_tmux_refresh_path)
fi

# Zoxide (smart cd)
_zsh_cached_init zoxide zoxide zoxide init zsh

# Worktree manager wrapper (wt go needs to cd in current shell)
wt() {
    if [[ "$1" == "go" ]]; then
        local dir
        dir=$("$HOME/.bin/wt" go "${@:2}")
        [[ -n "$dir" && -d "$dir" ]] && cd "$dir"
    else
        "$HOME/.bin/wt" "$@"
    fi
}

# Same wrapper for repos that live on the Windows filesystem (wtw go must cd too)
wtw() {
    if [[ "$1" == "go" ]]; then
        local dir
        dir=$("$HOME/.bin/wtw" go "${@:2}")
        [[ -n "$dir" && -d "$dir" ]] && cd "$dir"
    else
        "$HOME/.bin/wtw" "$@"
    fi
}

# Branch note quick-add
t() { "$HOME/.bin/bn" add todo "$*" }
unalias r 2>/dev/null  # override zsh's default r=fc (repeat last command)
r() { "$HOME/.bin/bn" add research "$*" }
c() { "$HOME/.bin/bn" add collab "$*" }
a() { "$HOME/.bin/bn" add ask "$*" }


# bn tab completion. NOT sourced: the generated script is 655KB and takes ~479ms
# to PARSE, so caching it to a file saved nothing — the cost was never the binary
# spawn. It begins with `#compdef bn`, which is exactly what zsh autoloads from
# $fpath, so writing it as _bn there defers the whole 479ms until the first time
# you actually tab-complete bn. Regenerated only when the binary is newer.
_zsh_completion_file bn bn bn completion zsh


export KUBECONFIG=/Users/edd/projects/kube/kubeconfig.local

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
export PATH="$HOME/.local/bin:$PATH"

# fzf is already sourced above (line ~81); sourcing it twice cost ~64ms for nothing.

# Starship
_zsh_cached_init starship starship starship init zsh

# fleet resource caps (added by copilot: tame per-lane build footprint)
export CARGO_BUILD_JOBS=4
export MAKEFLAGS="-j4"

# Rust build cache (added by copilot: cut rebuild time).
# mold: much faster linker on every build/link (helps all worktrees + the
# edit->test loop). sccache: caches dependency compilation, so clean rebuilds
# and target-wipe/CI-path rebuilds are ~8x faster (cross-worktree hits are
# limited: sccache's Rust key includes dep paths, so a fresh worktree misses).
# Guarded so these only activate where the tools are installed (portable no-op).
if command -v sccache >/dev/null 2>&1; then
  export RUSTC_WRAPPER=sccache
  export SCCACHE_CACHE_SIZE=20G     # deps are large; default 10G evicts too often
  # NB: leave CARGO_INCREMENTAL at default. cargo builds registry deps
  # non-incrementally (so sccache caches them on clean/CI-path rebuilds),
  # while your workspace crates keep fast incremental edits (sccache passes
  # those through uncached). Forcing =0 would cache your crates too but slow
  # the everyday edit->test loop, so we don't.
fi
if command -v mold >/dev/null 2>&1; then
  export RUSTFLAGS="${RUSTFLAGS:+$RUSTFLAGS }-C link-arg=-fuse-ld=mold"
fi
