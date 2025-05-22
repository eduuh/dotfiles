# Fast initial environment setup - keep this file minimal and fast
export GIT_EDITOR=nvim
unset NODE_OPTIONS

# Setup basic environment paths only once
export BUN_INSTALL="$HOME/.bun"
export NVM_DIR="$HOME/.nvm"

# Detect OS only once
export ZSHENV_OS=$(uname)

# Set paths based on OS detection - once
if [[ "$ZSHENV_OS" == "Darwin" ]]; then
    export PNPM_HOME="/Users/eduuh/Library/pnpm"
else
    export PNPM_HOME="$HOME/.local/share/pnpm"
fi

# Add to PATH only if not already there
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && export PATH="$PNPM_HOME:$PATH"
[[ ":$PATH:" != *":$BUN_INSTALL/bin:"* ]] && export PATH="$BUN_INSTALL/bin:$PATH"
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"

# Load cargo once if it exists
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"



