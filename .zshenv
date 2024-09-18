. "$HOME/.cargo/env"

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


[ -s "/Users/edwinmuraya/.bun/_bun" ] && source "/Users/edwinmuraya/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="/mnt/c/Users/edwinmuraya/AppData/Local/Programs/AzureAuth/0.8.6:$PATH"
