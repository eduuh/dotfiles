if [[ -s "$HOME/.cargo/env" ]]; then
   . "$HOME/.cargo/env"
fi

# Set Git editor globally
export GIT_EDITOR=nvim

# Unset NODE_OPTIONS globally to prevent conflicts
unset NODE_OPTIONS

# Essential paths
export BUN_INSTALL="$HOME/.bun"
export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$HOME/.local/bin:$BUN_INSTALL/bin:$PNPM_HOME:$PATH"

# macOS-specific paths
if [[ "$(uname)" == "Darwin" ]]; then
  export PATH="/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$PATH"
fi

