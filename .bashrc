# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export TERM=screen-256color

[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shortcutrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/aliasrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zshnameddirrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/zshnameddirrc"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

set -o vi

#PAth Detalis {{{
#/home/eduuh/.gem/ruby/2.7.0/bin
export DENO_INSTALL="/home/edd/.deno"
export PATH="$DENO_INSTALL/bin:/home/eduuh/.gem/ruby/2.7.0/bin:$PATH"
export PATH="$PATH:/home/eduuh/.dotnet/tools"
#}}}

#
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  alias nvm='unalias nvm node npm && . "$NVM_DIR"/nvm.sh && nvm'
  alias node='unalias nvm node npm && . "$NVM_DIR"/nvm.sh && node'
  alias npm='unalias nvm node npm && . "$NVM_DIR"/nvm.sh && npm'
fi

eval "$(starship init bash)"

alias bd=". bd -si"
