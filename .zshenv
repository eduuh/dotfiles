. "$HOME/.cargo/env"

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

if [[ "$(uname)" == "Darwin" ]]; then
    # bun completions
    [ -s "/Users/eduuh/yes/_bun" ] && source "/Users/eduuh/yes/_bun"
    export PNPM_HOME="/Users/eduuh/Library/pnpm"
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
else
    export PNPM_HOME="$HOME/.local/share/pnpm"
    case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
fi

if [[ -f ~/projects/work-dotfiles/.zshrc ]]; then
    source ~/projects/work-dotfiles/.zshrc
fi


