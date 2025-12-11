#!/bin/zsh

set -e
set -o pipefail

# Define common software based on environment
if [ "$CODESPACES" = "true" ]; then
    common_software=(
        git stow fzf ripgrep tmux zsh unzip neovim
    )
else
    common_software=(
        git stow make cmake fzf ripgrep tmux zsh unzip neovim
    )
fi

detect_distro() {
    if [ "$CODESPACES" = "true" ]; then
        echo "codespace"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ "$(uname)" = "Darwin" ]; then
        echo "darwin"
    else
        echo "Unknown"
    fi
}

clone_repos() {
  cd ~

  if [ ! -d ~/projects ]; then
    mkdir ~/projects
  fi

  if [ "$CODESPACES" = "true" ]; then
      REPOSITORIES=(
          "https://github.com/eduuh/dotfiles.git"
      )
  else
            REPOSITORIES=(
                "git@github.com:eduuh/byte_s.git"
                "git@github.com:eduuh/ai_s.git"
                "git@github.com:eduuh/homelab.git"
                "git@github.com:eduuh/nvim.git"
                "git@github.com:eduuh/dotfiles.git"
                "git@github.com:eduuh/bash.git"
                "git@github.com:eduuh/eduuh-blog-template.git"
                "git@github.com:eduuh/personal-notes.git"
                "git@github.com:eduuh/life.git"
            )
  fi

  for REPO in "${REPOSITORIES[@]}"; do
      REPO_NAME=$(basename "$REPO" .git)
      TARGET_DIR=~/projects/"$REPO_NAME"

      if [ -d "$TARGET_DIR" ]; then
          # Check if repo has unsaved changes
          cd "$TARGET_DIR"
          if [ -d ".git" ] && ! git diff --quiet || ! git diff --cached --quiet; then
              echo "Skipping $REPO_NAME: Found unsaved changes at $TARGET_DIR."
          else
              echo "Updating $REPO_NAME at $TARGET_DIR..."
              git pull origin "$(git symbolic-ref --short HEAD)" || echo "Failed to pull latest changes for $REPO_NAME"
          fi
          cd ~
      else
          echo "Cloning $REPO_NAME into $TARGET_DIR..."
          git clone "$REPO" "$TARGET_DIR" || echo "Failed to clone $REPO_NAME. Continuing..."
      fi

      # Special handling for Neovim config
      if [[ "$REPO_NAME" == "nvim" ]]; then
          echo "Creating symbolic link for Neovim config at ~/.config/nvim..."
          mkdir -p ~/.config
          ln -sf "$TARGET_DIR" ~/.config/nvim
      fi
  done
}

install_tmux_plugins() {
    local target_dir="$HOME/.tmux/plugins/tpm"

    if [ -d "$target_dir" ]; then
        echo "TPM is already installed at $target_dir."
        return 0
    fi

    echo "Cloning TPM repository..."
    if git clone https://github.com/tmux-plugins/tpm "$target_dir"; then
        echo "TPM has been successfully installed at $target_dir."
    else
        echo "Error: Failed to clone the TPM repository."
        return 1
    fi
}

install_lazygit() {
    if command -v lazygit &> /dev/null; then
        echo "LazyGit is already installed."
        return 0
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS installation via Homebrew
        brew install lazygit
    else
        # Linux installation
        if ! command -v curl &> /dev/null; then
            echo "Installing curl..."
            sudo apt-get install -y curl || sudo pacman -S --noconfirm curl
        fi

        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install -D lazygit -t /usr/local/bin/
        rm -f lazygit lazygit.tar.gz
    fi
}

install_starship() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping Starship installation."
        return 0
    fi

    if command -v starship &> /dev/null; then
        echo "Starship is already installed."
        return 0
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        echo "Installing Starship via Homebrew..."
        brew install starship
    else
        # Use -y to automatically accept prompts in non-interactive environments
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
}

install_rust() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping Rust installation."
        return 0
    fi

    if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
        echo "Rust is already installed."
        return 0
    fi

    echo "Installing Rust..."
    # Use -y flag to automatically accept the installation defaults
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # Source the cargo environment for the current session
    source "$HOME/.cargo/env"
}

install_pnpm() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping PNPM installation."
        return 0
    fi

    if command -v pnpm &> /dev/null; then
        echo "PNPM is already installed."
        return 0
    fi

    echo "Installing PNPM..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -s -- -y

    # Source PNPM environment for the current session
    export PNPM_HOME="$HOME/.local/share/pnpm"
    case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
}

install_talosctl() {
    if command -v talosctl &> /dev/null; then
        echo "talosctl is already installed."
        return 0
    fi

    echo "Installing talosctl..."
    curl -sL https://talos.dev/install | sh
}

setup_python() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping Python setup."
        return 0
    fi

    if [ -d "$HOME/.local/state/python3" ]; then
        echo "Python virtual environment already exists."
        source ~/.local/state/python3/bin/activate
    else
        echo "Creating Python virtual environment..."
        python3 -m venv ~/.local/state/python3
        source ~/.local/state/python3/bin/activate
    fi

    pip install --upgrade pip pynvim requests
}

install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        echo "NVM is already installed."
        return 0
    fi

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash -s -- --no-use --silent

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    nvm install --lts
}

setup_symlinks() {
    cd ~/projects/dotfiles
    stow --adopt -t "$HOME" .
}

setup_git_hooks() {
    echo "Setting up git hooks for all projects..."
    local hook_source="$HOME/projects/dotfiles/.bin/git-hooks/pre-push"
    
    if [ ! -f "$hook_source" ]; then
        echo "Error: Pre-push hook not found at $hook_source"
        return 1
    fi

    # Find all git repositories in ~/projects
    find ~/projects -maxdepth 2 -name ".git" -type d | while read git_dir; do
        local hook_dir="$git_dir/hooks"
        local hook_dest="$hook_dir/pre-push"
        
        # Skip if it's the dotfiles repo itself (optional, but maybe you want to protect dotfiles too)
        # if [[ "$git_dir" == *"/dotfiles/.git" ]]; then continue; fi

        echo "Installing pre-push hook in $(dirname "$git_dir")..."
        mkdir -p "$hook_dir"
        ln -sf "$hook_source" "$hook_dest"
    done
}

change_shell_to_zsh() {
    if [[ "$SHELL" != "/bin/zsh" ]]; then
        echo "Changing default shell to zsh..."

        # Handle platform-specific shell change commands
        case "$(detect_distro)" in
            darwin)
                # macOS doesn't need sudo for chsh
                chsh -s /bin/zsh
                ;;
            *)
                # Linux distributions typically need sudo
                sudo chsh -s /bin/zsh $USER
                ;;
        esac
    else
        echo "Shell is already set to zsh."
    fi
}
