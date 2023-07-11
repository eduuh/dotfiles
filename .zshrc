
if [[ "$OSTYPE" == "darwin"* ]]; then
  # add brew to path
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi

  ZSH_THEME="powerlevel10k/powerlevel10k"

  export ZSH="$HOME/.oh-my-zsh"

  # Add wisely, as too many plugins slow down shell startup.
  plugins=(git)

  source $ZSH/oh-my-zsh.sh

  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

  export PATH=$PATH:~/.bin
  export PATH=/Users/edwinmuraya/.local/bin:$PATH
fi

## Set up aliases
alias config='git --git-dir="$HOME/.cfg" --work-tree="$HOME"'
# run this command
# config config --local status.showUntrackedFiles no

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'e' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'n' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

_not_inside_tmux() { [[ -z "$TMUX" ]] }

ensure_tmux_is_running() {
  if _not_inside_tmux; then
    tat
  fi
}

ensure_tmux_is_running
