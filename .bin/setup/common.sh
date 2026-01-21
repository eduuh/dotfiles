#!/bin/zsh

# Failure tracking - collect errors instead of exiting
typeset -ga SETUP_FAILURES=()

track_failure() {
    local component="$1"
    local message="$2"
    SETUP_FAILURES+=("[$component] $message")
    echo "WARNING: $message (continuing...)"
}

# Run a command and track failure if it fails
run_or_track() {
    local component="$1"
    shift
    if ! "$@"; then
        track_failure "$component" "Failed: $*"
        return 1
    fi
    return 0
}

# Install a package with error tracking (generic wrapper)
install_package() {
    local pkg="$1"
    local install_cmd="$2"

    echo "Installing $pkg..."
    if ! eval "$install_cmd" 2>&1; then
        track_failure "package" "Failed to install $pkg"
        return 1
    fi
    return 0
}

# Print all failures at the end
print_failure_summary() {
    if [[ ${#SETUP_FAILURES[@]} -eq 0 ]]; then
        echo ""
        echo "=========================================="
        echo "  Setup completed with no failures!"
        echo "=========================================="
        return 0
    fi

    echo ""
    echo "=========================================="
    echo "  Setup completed with ${#SETUP_FAILURES[@]} failure(s):"
    echo "=========================================="
    for failure in "${SETUP_FAILURES[@]}"; do
        echo "  - $failure"
    done
    echo "=========================================="
    echo ""
    echo "You may need to manually fix these issues."
    return 1
}

# Define common software based on environment
# Note: zoxide is NOT in Ubuntu apt repos, so it's installed separately via install_zoxide
if [ "$CODESPACES" = "true" ]; then
    common_software=(
        git stow fzf ripgrep tmux zsh unzip neovim tree jq
    )
else
    common_software=(
        git stow make cmake fzf ripgrep tmux zsh unzip neovim tree jq
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

  # Detect if running on WSL
  local is_wsl=false
  if grep -qi microsoft /proc/version 2>/dev/null; then
      is_wsl=true
  fi

  if [ "$CODESPACES" = "true" ]; then
      REPOSITORIES=(
          "https://github.com/eduuh/dotfiles.git"
      )
  else
      # Base repos for all environments
      REPOSITORIES=(
          "git@github.com:eduuh/dotfiles.git"
          "git@github.com:eduuh/nvim.git"
          "git@github.com:eduuh-private/personal-notes.git"
      )

      # Additional repos to skip on WSL
      if [ "$is_wsl" = false ]; then
          REPOSITORIES+=(
              "git@github.com:eduuh/kube-homelab.git"
              "git@github.com:eduuh/blog-2026.git"
              "git@github.com:eduuh/tracker.git"
              "git@github.com:eduuh/growatt_exporter.git"
              "git@github.com:eduuh-private/byte_s.git"
              "git@github.com:eduuh-private/bash.git"
              "git@github.com:eduuh-private/eduuh-blog-template.git"
              "git@github.com:eduuh-private/life.git"
          )
      fi
  fi

  for REPO in "${REPOSITORIES[@]}"; do
      REPO_NAME=$(basename "$REPO" .git)
      PROJECT_ROOT=~/projects/"$REPO_NAME"
      BARE_DIR="$PROJECT_ROOT/.bare"
      CURRENT_WORKTREE=""

      if [ -d "$PROJECT_ROOT" ]; then
          if [ -d "$BARE_DIR" ]; then
              echo "Updating $REPO_NAME (bare)..."
              cd "$BARE_DIR"
              git fetch origin
              DEFAULT_BRANCH=$(git symbolic-ref --short HEAD)
              CURRENT_WORKTREE="$PROJECT_ROOT/$DEFAULT_BRANCH"
              
              if [ -d "$CURRENT_WORKTREE" ]; then
                  cd "$CURRENT_WORKTREE"
                  git pull origin "$DEFAULT_BRANCH" || echo "Failed to pull latest changes for $REPO_NAME"
              fi
          elif [ -d "$PROJECT_ROOT/.git" ]; then
              # Old style
              CURRENT_WORKTREE="$PROJECT_ROOT"
              cd "$PROJECT_ROOT"
              if ! git diff --quiet || ! git diff --cached --quiet; then
                  echo "Skipping $REPO_NAME: Found unsaved changes at $PROJECT_ROOT."
              else
                  echo "Updating $REPO_NAME at $PROJECT_ROOT..."
                  git pull origin "$(git symbolic-ref --short HEAD)" || echo "Failed to pull latest changes for $REPO_NAME"
              fi
          else
              echo "Directory $PROJECT_ROOT exists but is not a git repo. Skipping."
          fi
          cd ~
      else
          echo "Cloning $REPO_NAME (bare) into $PROJECT_ROOT..."
          mkdir -p "$PROJECT_ROOT"
          git clone --bare "$REPO" "$BARE_DIR" || { echo "Failed to clone $REPO_NAME. Continuing..."; continue; }
          
          cd "$BARE_DIR"
          DEFAULT_BRANCH=$(git symbolic-ref --short HEAD)
          CURRENT_WORKTREE="$PROJECT_ROOT/$DEFAULT_BRANCH"
          
          echo "Creating worktree for $DEFAULT_BRANCH..."
          git worktree add "$CURRENT_WORKTREE" "$DEFAULT_BRANCH"
      fi

      # Special handling for Neovim config
      if [[ "$REPO_NAME" == "nvim" ]] && [[ -n "$CURRENT_WORKTREE" ]]; then
          echo "Creating symbolic link for Neovim config at ~/.config/nvim..."
          mkdir -p ~/.config
          ln -sf "$CURRENT_WORKTREE" ~/.config/nvim
      fi
  done
}

ensure_tmux_version() {
    local min_version="3.2"

    # macOS via Homebrew always has recent tmux, skip
    if [[ "$(uname)" == "Darwin" ]]; then
        return 0
    fi

    # Check current tmux version
    if command -v tmux &> /dev/null; then
        local current_version
        current_version=$(tmux -V | sed -n 's/^tmux \([0-9.]*\).*/\1/p')

        if [[ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" == "$min_version" ]]; then
            echo "tmux $current_version is installed (>= $min_version required). OK."
            return 0
        fi
        echo "tmux $current_version is too old (need >= $min_version). Installing from source..."
    else
        echo "tmux not found. Installing from source..."
    fi

    # Install build dependencies based on distro
    echo "Installing tmux build dependencies..."
    if command -v pacman &> /dev/null; then
        sudo pacman -S --needed --noconfirm libevent ncurses base-devel bison pkg-config || {
            track_failure "tmux" "Failed to install tmux build dependencies"
            return 1
        }
    else
        sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config || {
            track_failure "tmux" "Failed to install tmux build dependencies"
            return 1
        }
    fi

    # Build tmux from source
    local tmux_version="3.5a"
    local build_dir="/tmp/tmux-build"

    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir" || return 1

    echo "Downloading tmux $tmux_version..."
    if ! curl -sLO "https://github.com/tmux/tmux/releases/download/${tmux_version}/tmux-${tmux_version}.tar.gz"; then
        track_failure "tmux" "Failed to download tmux source"
        cd ~ || return 1
        return 1
    fi

    tar -xzf "tmux-${tmux_version}.tar.gz"
    cd "tmux-${tmux_version}" || return 1

    echo "Building tmux..."
    if ! ./configure && make; then
        track_failure "tmux" "Failed to build tmux"
        cd ~ || return 1
        return 1
    fi

    echo "Installing tmux..."
    if ! sudo make install; then
        track_failure "tmux" "Failed to install tmux"
        cd ~ || return 1
        return 1
    fi

    cd ~ || return 1
    rm -rf "$build_dir"

    echo "tmux $(tmux -V) installed successfully."
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
        track_failure "tmux" "Failed to clone TPM repository"
    fi
}

install_lazygit() {
    if command -v lazygit &> /dev/null; then
        echo "LazyGit is already installed."
        return 0
    fi

    echo "Installing LazyGit..."
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS installation via Homebrew
        if ! brew install lazygit; then
            track_failure "lazygit" "Failed to install lazygit via Homebrew"
        fi
    else
        # Linux installation
        if ! command -v curl &> /dev/null; then
            echo "Installing curl..."
            sudo apt-get install -y curl || sudo pacman -S --noconfirm curl || {
                track_failure "lazygit" "Failed to install curl (required for lazygit)"
                return 0
            }
        fi

        local lazygit_version
        lazygit_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
        if [[ -z "$lazygit_version" ]]; then
            track_failure "lazygit" "Failed to fetch lazygit version"
            return 0
        fi

        if curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_x86_64.tar.gz" && \
           tar xf lazygit.tar.gz lazygit && \
           sudo install -D lazygit -t /usr/local/bin/; then
            rm -f lazygit lazygit.tar.gz
        else
            rm -f lazygit lazygit.tar.gz
            track_failure "lazygit" "Failed to download/install lazygit"
        fi
    fi
}

install_zoxide() {
    if command -v zoxide &> /dev/null; then
        echo "zoxide is already installed."
        return 0
    fi

    echo "Installing zoxide..."
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS installation via Homebrew
        if ! brew install zoxide; then
            track_failure "zoxide" "Failed to install zoxide via Homebrew"
        fi
    else
        # Linux installation via official install script
        if ! curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
            track_failure "zoxide" "Failed to install zoxide via install script"
        else
            # Add to PATH for current session if installed to ~/.local/bin
            if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                export PATH="$HOME/.local/bin:$PATH"
            fi
        fi
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

    echo "Installing Starship..."
    if [[ "$(uname)" == "Darwin" ]]; then
        if ! brew install starship; then
            track_failure "starship" "Failed to install starship via Homebrew"
        fi
    else
        if ! curl -sS https://starship.rs/install.sh | sh -s -- -y; then
            track_failure "starship" "Failed to install starship"
        fi
    fi
}

install_claude_code() {
    if command -v claude &> /dev/null; then
        echo "Claude Code is already installed."
        return 0
    fi

    echo "Installing Claude Code..."
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        track_failure "claude-code" "Failed to install Claude Code"
    fi
}

install_claude_code() {
    if command -v claude &> /dev/null; then
        echo "Claude Code is already installed."
        return 0
    fi

    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
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
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        # Source the cargo environment for the current session
        [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    else
        track_failure "rust" "Failed to install Rust"
    fi
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
    if curl -fsSL https://get.pnpm.io/install.sh | sh -s -- -y; then
        # Source PNPM environment for the current session
        export PNPM_HOME="$HOME/.local/share/pnpm"
        case ":$PATH:" in
            *":$PNPM_HOME:"*) ;;
            *) export PATH="$PNPM_HOME:$PATH" ;;
        esac
    else
        track_failure "pnpm" "Failed to install PNPM"
    fi
}

install_talosctl() {
    # Skip on WSL - talosctl should be installed on Windows host
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "Skipping talosctl on WSL (install on Windows host instead)."
        return 0
    fi

    if command -v talosctl &> /dev/null; then
        echo "talosctl is already installed."
        return 0
    fi

    echo "Installing talosctl..."
    if ! curl -sL https://talos.dev/install | sh; then
        track_failure "talosctl" "Failed to install talosctl"
    fi
}

setup_python() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping Python setup."
        return 0
    fi

    echo "Setting up Python environment..."
    if [ -d "$HOME/.local/state/python3" ]; then
        echo "Python virtual environment already exists."
        source ~/.local/state/python3/bin/activate
    else
        echo "Creating Python virtual environment..."
        if ! python3 -m venv ~/.local/state/python3; then
            track_failure "python" "Failed to create Python virtual environment"
            return 0
        fi
        source ~/.local/state/python3/bin/activate
    fi

    if ! pip install --upgrade pip pynvim requests; then
        track_failure "python" "Failed to install Python packages (pip, pynvim, requests)"
    fi
}

install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        echo "NVM is already installed."
        return 0
    fi

    echo "Installing NVM..."
    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash -s -- --no-use --silent; then
        track_failure "nvm" "Failed to install NVM"
        return 0
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

    if ! nvm install --lts; then
        track_failure "nvm" "Failed to install Node.js LTS via NVM"
    fi
}

setup_symlinks() {
    local dotfiles_dir=~/projects/dotfiles

    # Check if it's the new structure
    if [ -d "$dotfiles_dir/.bare" ]; then
         cd "$dotfiles_dir/.bare"
         local default_branch=$(git symbolic-ref --short HEAD)
         dotfiles_dir="$dotfiles_dir/$default_branch"
    fi

    echo "Stowing dotfiles from $dotfiles_dir..."
    cd "$dotfiles_dir"
    if ! stow --adopt -t "$HOME" .; then
        track_failure "symlinks" "Failed to create symlinks with stow"
    fi
}

setup_git_hooks() {
    echo "Setting up git hooks for all projects..."
    local hook_source="$HOME/projects/dotfiles/.bin/git-hooks/pre-push"

    # Try to locate hook source dynamically if not found
    if [ ! -f "$hook_source" ]; then
        local potential_source=$(find "$HOME/projects/dotfiles" -maxdepth 2 -path "*/.bin/git-hooks/pre-push" | head -n 1)
        if [ -n "$potential_source" ]; then
            hook_source="$potential_source"
        fi
    fi

    if [ ! -f "$hook_source" ]; then
        track_failure "git-hooks" "Pre-push hook not found at $hook_source"
        return 0
    fi

    # Iterate over projects
    for project in ~/projects/*; do
        local hook_dir=""
        if [ -d "$project/.bare" ]; then
            # New structure
            hook_dir="$project/.bare/hooks"
        elif [ -d "$project/.git" ]; then
            # Old structure
            hook_dir="$project/.git/hooks"
        fi

        if [ -n "$hook_dir" ]; then
            echo "Installing pre-push hook in $project..."
            mkdir -p "$hook_dir"
            if ! ln -sf "$hook_source" "$hook_dir/pre-push"; then
                track_failure "git-hooks" "Failed to install hook in $(basename $project)"
            fi
        fi
    done
}

change_shell_to_zsh() {
    if [[ "$SHELL" != "/bin/zsh" ]]; then
        echo "Changing default shell to zsh..."

        # Handle platform-specific shell change commands
        case "$(detect_distro)" in
            darwin)
                # macOS doesn't need sudo for chsh
                if ! chsh -s /bin/zsh; then
                    track_failure "shell" "Failed to change shell to zsh"
                fi
                ;;
            *)
                # Linux distributions typically need sudo
                if ! sudo chsh -s /bin/zsh $USER; then
                    track_failure "shell" "Failed to change shell to zsh"
                fi
                ;;
        esac
    else
        echo "Shell is already set to zsh."
    fi
}
