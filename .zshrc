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

unset NODE_OPTIONS

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

export PATH="${PATH}:/Users/edwinmurayawork/.azureauth/0.8.4"

export PATH="${PATH}:~/projects/byte_safari/tools/bash/"

unset NODE_OPTIONS

# export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="robbyrussell"
# plugins=()
#
# source $ZSH/oh-my-zsh.sh
# bun completions

[ -s "/Users/edwinmuraya/.bun/_bun" ] && source "/Users/edwinmuraya/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# setopt PROMPT_SUBST
# # PROMPT='%F{green}%f %F{blue}%~%f %F{red}%f$ '
# # PROMPT='%F{green}%f %F{blue}%1~%f %F{red}%f$ '
# PROMPT='%F{blue}%1~$ '

eval "$(starship init zsh)"
