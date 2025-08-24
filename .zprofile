# Load OS-specific configurations based on variables set in .zshenv
if [ -f ~/.config/shell/profile ]; then
    . ~/.config/shell/profile
fi

if [[ "$ZSHENV_OS" == "Darwin" ]]; then
   # Only run Homebrew setup on macOS
   [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Lazy load NVM only when needed
nvm() {
  unset -f nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
  nvm "$@"
}

# Add additional paths conditionally
paths_to_add=(
  "$HOME/.azureauth/0.8.4"
  "$HOME/projects/byte_safari/tools/bash"
)

# Add WSL-specific paths if needed
if [[ -d /mnt/c ]]; then
  paths_to_add+=(
    "/mnt/c/Users/edwinmuraya/AppData/Local/Microsoft/WindowsApps"
    "/mnt/c/Users/edwinmuraya/scoop/shims"
    "/mnt/c/Program Files/PowerShell/7-preview"
    "/mnt/c/Windows/System32"
  )
fi

# Add all paths efficiently in one operation
for p in "${paths_to_add[@]}"; do
  [[ -d "$p" && ":$PATH:" != *":$p:"* ]] && PATH="$PATH:$p"
done
export PATH
export PATH="/home/eduuh/.local/share/pnpm:/home/edd/.nvm/versions/node/v22.18.0/bin:/home/edd/.local/share/pnpm:/home/edd/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/edd/.vector/bin"
