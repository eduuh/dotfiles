# run this command
# config config --local status.showUntrackedFiles no
bindkey -v
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'l' vi-forward-char

## Environment variables
export GIT_EDITOR=nvim
export PATH=$PATH:~/.bin
export PATH=/Users/edwinmuraya/.local/bin:$PATH

_not_inside_tmux() { [[ -z "$TMUX" ]] }

ensure_tmux_is_running() {
  if _not_inside_tmux; then
    tat
  fi
}

ensure_tmux_is_running

eval "$(starship init zsh)"

# Reference
# https://thevaluable.dev/zsh-completion-guide-examples/
