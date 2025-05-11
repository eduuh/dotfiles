bindkey -v
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'l' vi-forward-char

alias nav='cd "$(find . -type d | fzf)"'
alias gdel='git branch | grep -v "main" | xargs git branch -D'
alias cat='bat'
alias ls='ls -la --color'
alias zz='z -'

export PNPM_HOME="/home/eduuh/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

if [[ "$(uname)" == "Darwin" ]]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"
  export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
fi

# bun completions
[ -s "/Users/eduuh/yes/_bun" ] && source "/Users/eduuh/yes/_bun"

# bun
export BUN_INSTALL="yes"
export PATH="$BUN_INSTALL/bin:$PATH"

eval "$(starship init zsh)"
