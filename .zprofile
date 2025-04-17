if [[ "$(uname)" == "Darwin" ]]; then
   eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Load NVM (only in login shells)
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# Load Envman if available
[[ -s "$HOME/.config/envman/load.sh" ]] && source "$HOME/.config/envman/load.sh"

# Add Azure auth & Byte Safari tools if applicable
export PATH="$PATH:$HOME/.azureauth/0.8.4:$HOME/projects/byte_safari/tools/bash/"

# Tmux auto-start (only for login shells)
ensure_tmux_is_running() {
  [[ -z "$TMUX" ]] && "$HOME/.bin/tat.sh"
}

ensure_tmux_is_running

eval "$(starship init zsh)"
