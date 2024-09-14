# run this command
# config config --local status.showUntrackedFiles no
bindkey -v
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'l' vi-forward-char

export PATH=”$HOME/.emacs.d/bin:$HOME/.bin:$PATH”
## Environment variables
export GIT_EDITOR=nvim

_not_inside_tmux() { [[ -z "$TMUX" ]] }

ensure_tmux_is_running() {
  if _not_inside_tmux; then
    tat
  fi
}

ensure_tmux_is_running

alias nav='cd "$(find . -type d | fzf)"'
alias gdel='git branch | grep -v "main" | xargs git branch -D'
alias cat='bat'
alias ls='ls -la --color'
alias cd='z'
alias zz='z -'

unset NODE_OPTIONS

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

export PATH="${PATH}:/Users/edwinmurayawork/.azureauth/0.8.4"

export PATH="${PATH}:~/projects/byte_safari/tools/bash/"

unset NODE_OPTIONS


[ -s "/Users/edwinmuraya/.bun/_bun" ] && source "/Users/edwinmuraya/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
export PATH="/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$PATH"

# Check if running on macOS
if [[ "$(uname)" == "Darwin" ]]; then
  # pnpm setup
  export PNPM_HOME="/Users/edwinmuraya/Library/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
  # pnpm end
fi

# Check if running on macOS
if [[ "$(uname)" == "Darwin" ]]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"   # This loads nvm bash_completion
fi
