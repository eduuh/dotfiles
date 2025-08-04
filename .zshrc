# Load lazy loading functions
[[ -f "$HOME/projects/dotfiles/.zsh_lazy_load" ]] && source "$HOME/projects/dotfiles/.zsh_lazy_load"

# VI mode and key bindings - only loaded once in interactive shells
bindkey -v
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# Faster history search with arrow keys
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# More efficient history settings
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# Aliases - simple and fast
alias ll='ls -la --color'
alias ls='ls --color'
alias cat='bat'
alias zz='z -'

# Lazy loaded aliases for commands that call external programs
lazy_load nav 'alias nav="cd \"\$(find . -type d | fzf)\""'
lazy_load gdel 'alias gdel="git branch | grep -v \"main\" | xargs git branch -D"'

# OS-specific configurations using pre-set ZSHENV_OS variable
if [[ "$ZSHENV_OS" == "Darwin" ]]; then
  # Preload Android SDK paths efficiently
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  if [[ -d "$ANDROID_HOME/ndk" ]]; then
    NDK_DIR=$(ls -1 "$ANDROID_HOME/ndk" 2>/dev/null | head -1)
    [[ -n "$NDK_DIR" ]] && export NDK_HOME="$ANDROID_HOME/ndk/$NDK_DIR"
  fi
  
  # Android tools paths
  android_paths=(
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/tools"
    "$ANDROID_HOME/tools/bin"
    "$ANDROID_HOME/platform-tools"
  )
  
  # Add Android paths efficiently
  for p in "${android_paths[@]}"; do
    [[ -d "$p" && ":$PATH:" != *":$p:"* ]] && PATH="$PATH:$p"
  done
  
  # Bun completions - only on macOS - lazy loaded
  lazy_load _bun_completion '[[ -s "/Users/eduuh/yes/_bun" ]] && source "/Users/eduuh/yes/_bun"'
fi

# Source work configurations if they exist
[[ -f ~/projects/work-dotfiles/.zshrc ]] && source ~/projects/work-dotfiles/.zshrc

# Initialize starship prompt efficiently with caching
if [[ ! -f ~/.starship.zsh || ! -s ~/.starship.zsh || "$(find ~/.starship.zsh -mtime +1)" != "" ]]; then
  # Cache doesn't exist, is empty, or older than 1 day
  starship init zsh > ~/.starship.zsh
fi
source ~/.starship.zsh

# pnpm
export PNPM_HOME="/home/eduuh/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
