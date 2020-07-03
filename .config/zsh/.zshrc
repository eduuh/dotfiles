# Enable colors and change prompt:
autoload -U colors && colors	# Load colors
PS1="%B%{$fg[red]%}[😎%{$fg[yellow]%}%n%{$fg[green]%} %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.

# History in cache directory:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/history
export TERM=screen-256color

# Load aliases and shortcuts if existent.
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shortcutrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/aliasrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zshnameddirrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/zshnameddirrc"

# User configuration
# Always work in a tmux session if tmux is installed
# https://github.com/chrishunt/dot-files/blob/master/.zshrc

# Basic auto/tab complete:
# Enable completions
if [ -d ~/.zsh/comp ]; then
    fpath=(~/.zsh/comp $fpath)
    autoload -U ~/.zsh/comp/*(:t)
fi

autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.

# vi mode
bindkey -v
## Colemak.
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

export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'e' vi-up-line-or-history
bindkey -M menuselect 'i' vi-forward-char
bindkey -M menuselect 'n' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes.
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

# Use lf to switch directories and bind it to ctrl-o
lfcd () {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp" >/dev/null
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bindkey -s '^o' 'lfcd\n'
bindkey -s '^a' 'bc -l\n'
bindkey -s '^f' 'cd "$(dirname "$(fzf)")"\n'
bindkey '^[[P' delete-char

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# Load syntax highlighting; should be last.
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh 2>/dev/null

alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
export NVM_DIR=/home/edd/.config/nvm
[ -s /nvm.sh ] && \. /nvm.sh  # This loads nvm
[ -s /bash_completion ] && \. /bash_completion  # This loads nvm bash_completion


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export DENO_INSTALL="/home/edd/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

if [ -z "$TMUX" ]
then
    tmux attach -t TMUX || tmux new -s TMUX
fi

# options fzf
# fzf
####################################################################################################
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  # Make sure FZF uses ag (which respects .gitignore files) and ignores .git dirs itself.
  export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
  export FZF_DEFAULT_OPTS=''
  # Match exact words (don't fuzzy match foo to fzozo)
  export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' --exact'
  # Up/down wraps to top/bottom of results
  export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' --cycle'
  # Input on top, results below
  export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' --reverse'
  # Some margin to differentiate fzf appearance
  export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' --margin=0,4'
  # Custom key bindings
  export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' --bind=ctrl-n:down,ctrl-e:up,ctrl-f:page-down,ctrl-b:page-up'
  # Use tmux panes for fzf to avoid the shell output getting pushed around.
  export FZF_TMUX=1


