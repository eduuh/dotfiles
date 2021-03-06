export TERM=screen-256color
# ZshOptions {{{
setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/history

#bindkey '^H' backward-kill-word
##Aliases{{{
function expand_alias(){
       zle _expand_alias
       zle self-insert
}
zle -N expand_alias
bindkey -M main . expand_alias

export ZSH="/home/eduuh/.oh-my-zsh"

plugins=(
  git
)
#ZSH_THEME="robbyrussell"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shortcutrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/aliasrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zshnameddirrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/zshnameddirrc"

#}}}
 #Always work in a tmux session if tmux is installed
 #https://github.com/chrishunt/dot-files/blob/master/.zshrc
#if [ -z "$TMUX" ]
#then
    #tmux attach -t DEV || tmux new -s DEV
#fi

mkcd() {
  mkdir "$1"
  cd "$1"
}

#function tmuxdettach {
    #tmux  detach
    #tmux new -s TMUX
#}
## Colemak bindings {{{
bindkey -M vicmd "h" backward-char
bindkey -M vicmd "n" down-line-or-history
bindkey -M vicmd "e" up-line-or-history
bindkey -M vicmd "i" forward-char
bindkey -M vicmd "s" vi-insert
bindkey -M vicmd "S" vi-insert-bol
bindkey -M vicmd "k" vi-repeat-search
bindkey -M vicmd "K" vi-rev-repeat-search
bindkey -M vicmd "l" beginning-of-line
bindkey -M vicmd "L" end-of-line
bindkey -M vicmd "j" vi-forward-word-end
bindkey -M vicmd "J" vi-forward-blank-word-end
# Sane Undo, Redo, Backspace, Delete.
bindkey -M vicmd "u" undo
bindkey -M vicmd "U" redo
bindkey -M vicmd "^?" backward-delete-char
bindkey -M vicmd "^[[3~" delete-char
# Keep ctrl+r searching
bindkey -M viins '^R' history-incremental-pattern-search-forward
bindkey -M viins '^r' history-incremental-pattern-search-backward      

bindkey -s '^f' 'cd "$(dirname "$(fzf)")"\n'
#}}}

vi-append-x-selection () { RBUFFER=$(xsel -o -p </dev/null)$RBUFFER; }
zle -N vi-append-x-selection
bindkey -a 'y' vi-append-x-selection
vi-yank-x-selection () { print -rn -- $CUTBUFFER | xsel -i -p; }
zle -N vi-yank-x-selection
bindkey -a 'p' vi-yank-x-selection

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

## Fzf installation {{{
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --no-ignore-vcs -g "!{node_modules,.git,obj,bin}"'

alias fzfi='rg --files --hidden --follow --no-ignore-vcs -g "!{node_modules,.git}" | fzf'
alias vifi='nvim $(fzfi)'

#}}}
#source $ZSH/oh-my-zsh.sh

# Enable colors and change prompt:
autoload -U colors && colors	# Load colors
#PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%} %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
# vi mode {{{
bindkey -v
export KEYTIMEOUT=1

# ci", ci', ci`, di", etc
autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
  for c in {a,i}{\',\",\`}; do
    bindkey -M $m $c select-quoted
  done
done

# ci{, ci(, ci<, di{, etc
autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $m $c select-bracketed
  done
done
##}}}

# Basic auto/tab complete: {{{
autoload -U compinit
zstyle ':completion:*' menu select
# Auto complete with case insenstivity
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.
#}}}

# Load syntax highlighting; should be last.
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh 2>/dev/null

#eval "$(starship init zsh)"
# Change Cursor Shape for Diffrent vi Modes{{{
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.
#}}}

alias kubectl='microk8s.kubectl'
source $HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source /home/eduuh/.zsh/history.zsh

## custom
PROMPT='%(?.%F{green}√.%F{red}?%?)%f %B%F{240}%1~%f%b %# '
#RPROMPT='%*'

function tn() (
    if [ -n "$1" ]
      then
         tmux switch -t $1
      else
         echo "no session name"
     fi
  )


function solo {
  unset GIT_COMMITTER_NAME
  unset GIT_COMMITTER_EMAIL
}

function pair_with_ {
  export GIT_COMMITTER_NAME=$1
  export GIT_COMMITTER_EMAIL=$2
}

function pair_with_hum {
    pair_with_ "Humphryshikunzi" "humphry.shikunzi@outlook.com"
}
