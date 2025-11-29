# ----------------------------------------
# Lazy-load helpers & safety
# ----------------------------------------

# Load lazy loading functions (if present)
if [[ -f "$HOME/projects/dotfiles/.zsh_lazy_load" ]]; then
  source "$HOME/projects/dotfiles/.zsh_lazy_load"
fi

# Fallback lazy_load implementation if function is missing
if ! typeset -f lazy_load >/dev/null 2>&1; then
  lazy_load() {
    # Usage: lazy_load <name> '<command to eval>'
    # Fallback: just eval the payload immediately
    local _name="$1"
    shift
    eval "$@"
  }
fi

# ----------------------------------------
# VI mode and key bindings
# ----------------------------------------

bindkey -v
zmodload zsh/complist 2>/dev/null || true

# Faster history search with arrow keys
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# ----- Ctrl+R fuzzy history search -----
if command -v fzf >/dev/null 2>&1; then
  fzf-history-widget() {
    # Use history, newest first, pipe into fzf
    local selected
    selected=$(fc -rl 1 | fzf --height 40% --reverse --inline-info --tac \
      | sed 's/^[[:space:]]*[0-9]\+[[:space:]]*//') || return

    LBUFFER="$selected"
    CURSOR=${#LBUFFER}
    zle redisplay
  }

  zle -N fzf-history-widget
  bindkey '^R' fzf-history-widget
else
  # Fallback: standard incremental history search
  bindkey '^R' history-incremental-search-backward
fi
# ----- end Ctrl+R fuzzy history -----


# ----------------------------------------
# History settings
# ----------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# ----------------------------------------
# Aliases (portable-ish)
# ----------------------------------------

# Use different ls flags per OS if you want portability
if [[ "$ZSHENV_OS" == "Darwin" ]]; then
  alias ls='ls -G'
  alias ll='ls -laG'
else
  alias ls='ls --color=auto'
  alias ll='ls -la --color=auto'
fi

alias cat='bat'
alias zz='z -'

# Lazy loaded aliases for external-heavy commands
lazy_load nav 'alias nav='\''cd "$(find . -type d 2>/dev/null | fzf)"'\'''
lazy_load gdel 'alias gdel='\''git branch | grep -v "main" | xargs git branch -D'\'''

# ----------------------------------------
# macOS-specific configuration
# ----------------------------------------

if [[ "$ZSHENV_OS" == "Darwin" ]]; then
  # Android SDK
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  if [[ -d "$ANDROID_HOME/ndk" ]]; then
    NDK_DIR=$(ls -1 "$ANDROID_HOME/ndk" 2>/dev/null | head -1)
    [[ -n "$NDK_DIR" ]] && export NDK_HOME="$ANDROID_HOME/ndk/$NDK_DIR"
  fi

  android_paths=(
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/tools"
    "$ANDROID_HOME/tools/bin"
    "$ANDROID_HOME/platform-tools"
  )

  for p in "${android_paths[@]}"; do
    [[ -d "$p" && ":$PATH:" != *":$p:"* ]] && PATH="$PATH:$p"
  done

  # Bun completions - path made relative to HOME & fully guarded
  if [[ -s "$HOME/yes/_bun" ]]; then
    lazy_load _bun_completion 'source "$HOME/yes/_bun"'
  fi
fi

# ----------------------------------------
# Work config (optional)
# ----------------------------------------

if [[ -f "$HOME/projects/work-dotfiles/.zshrc" ]]; then
  source "$HOME/projects/work-dotfiles/.zshrc"
fi

# ----------------------------------------
# Starship prompt (safe & cached)
# ----------------------------------------

if command -v starship >/dev/null 2>&1; then
  if [[ ! -f "$HOME/.starship.zsh" || ! -s "$HOME/.starship.zsh" || "$(find "$HOME/.starship.zsh" -mtime +1 2>/dev/null)" != "" ]]; then
    # Cache doesn't exist, is empty, or older than 1 day
    starship init zsh > "$HOME/.starship.zsh"
  fi
  source "$HOME/.starship.zsh"
fi

# ----------------------------------------
# pnpm
# ----------------------------------------

export PNPM_HOME="$HOME/.local/share/pnpm"
if [[ -d "$PNPM_HOME" && ":$PATH:" != *":$PNPM_HOME:"* ]]; then
  export PATH="$PNPM_HOME:$PATH"
fi

# ----------------------------------------
# fzf
# ----------------------------------------

if [[ -f "$HOME/.fzf.zsh" ]]; then
  source "$HOME/.fzf.zsh"
fi

# ----------------------------------------
# snap (Linux only, and only if directory exists)
# ----------------------------------------

if [[ -d /snap/bin && ":$PATH:" != *":/snap/bin:"* ]]; then
  export PATH="$PATH:/snap/bin"
fi

# ----------------------------------------
# NVM lazy load (Node 22.18.0 default)
# ----------------------------------------

export NVM_DIR="$HOME/.nvm"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  _nvm_lazy_load() {
    # Load nvm only when first needed
    unset -f nvm node npm npx
    source "$NVM_DIR/nvm.sh"

    # Use default (you already aliased this to 22.18.0)
    nvm use default &>/dev/null || true
  }

  nvm() { _nvm_lazy_load; nvm "$@"; }
  node() { _nvm_lazy_load; node "$@"; }
  npm() { _nvm_lazy_load; npm "$@"; }
  npx() { _nvm_lazy_load; npx "$@"; }
fi

# ----------------------------------------
# Vector code / other env loaders
# ----------------------------------------

if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi
