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
        git stow ripgrep tmux zsh unzip tree jq
    )
else
    common_software=(
        git stow make cmake ripgrep tmux zsh unzip tree jq
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

# Repos that get regular (non-bare) clones at ~/projects/reponame
REGULAR_CLONE_REPOS=(dotfiles nvim personal-notes eduuh)

_is_regular_repo() {
    local name="$1"
    for r in "${REGULAR_CLONE_REPOS[@]}"; do
        [[ "$name" == "$r" ]] && return 0
    done
    return 1
}

_clone_single_repo() {
    local REPO="$1"
    local REPO_NAME=$(basename "$REPO" .git)

    if _is_regular_repo "$REPO_NAME"; then
        local CLONE_DIR=~/projects/"$REPO_NAME"

        if [ -d "$CLONE_DIR" ]; then
            if [ -d "$CLONE_DIR/.git" ]; then
                cd "$CLONE_DIR"
                if ! git diff --quiet || ! git diff --cached --quiet; then
                    echo "[$REPO_NAME] Skipping: unsaved changes."
                else
                    echo "[$REPO_NAME] Updating..."
                    git pull origin "$(git symbolic-ref --short HEAD)" || echo "[$REPO_NAME] Failed to pull."
                fi
                cd ~
            else
                echo "[$REPO_NAME] Directory exists but is not a git repo. Skipping."
            fi
        else
            echo "[$REPO_NAME] Cloning (regular)..."
            git clone "$REPO" "$CLONE_DIR" || { echo "[$REPO_NAME] Failed to clone."; return 1; }
        fi

        # Special handling for Neovim config
        if [[ "$REPO_NAME" == "nvim" ]]; then
            mkdir -p ~/.config
            ln -sf "$CLONE_DIR" ~/.config/nvim
        fi
    else
        local BARE_PATH=~/projects/bare/"${REPO_NAME}.git"
        local WT_BASE=~/projects/worktree/"$REPO_NAME"

        if [ -d "$BARE_PATH" ]; then
            echo "[$REPO_NAME] Updating (bare)..."
            cd "$BARE_PATH"
            git fetch origin
            local DEFAULT_BRANCH=$(git symbolic-ref --short HEAD)
            local CURRENT_WORKTREE="$WT_BASE/$DEFAULT_BRANCH"

            if [ -d "$CURRENT_WORKTREE" ]; then
                cd "$CURRENT_WORKTREE"
                git pull origin "$DEFAULT_BRANCH" || echo "[$REPO_NAME] Failed to pull."
            fi
            cd ~
        else
            echo "[$REPO_NAME] Cloning (bare)..."
            git clone --bare "$REPO" "$BARE_PATH" || { echo "[$REPO_NAME] Failed to clone."; return 1; }

            cd "$BARE_PATH"
            git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
            git fetch origin
            local DEFAULT_BRANCH=$(git symbolic-ref --short HEAD)

            mkdir -p "$WT_BASE"
            git worktree add "$WT_BASE/$DEFAULT_BRANCH" "$DEFAULT_BRANCH"
            cd ~
        fi
    fi
}

clone_repos() {
    cd ~
    mkdir -p ~/projects ~/projects/bare ~/projects/worktree

    # Detect if running on WSL
    local is_wsl=false
    if grep -qi microsoft /proc/version 2>/dev/null; then
        is_wsl=true
    fi

    local REPOSITORIES=()
    if [ "$CODESPACES" = "true" ]; then
        REPOSITORIES=(
            "https://github.com/eduuh/dotfiles.git"
        )
    else
        REPOSITORIES=(
            "git@github.com:eduuh/dotfiles.git"
            "git@github.com:eduuh/nvim.git"
            "git@github.com:eduuh-private/personal-notes.git"
            "git@github.com:eduuh/eduuh.git"
        )

        if [ "$is_wsl" = true ] && [ "$(hostname)" = "edwin" ]; then
            REPOSITORIES+=(
                "git@github.com:eduuh/wira360.git"
            )
        elif [ "$is_wsl" = false ]; then
            REPOSITORIES+=(
                "git@github.com:eduuh/kube-homelab.git"
                "git@github.com:eduuh/blog-2026.git"
                "git@github.com:eduuh/growatt_exporter.git"
                "git@github.com:eduuh-private/byte_s.git"
                "git@github.com:eduuh-private/bash.git"
                "git@github.com:eduuh-private/eduuh-blog-template.git"
                "git@github.com:eduuh-private/life.git"
                "git@github.com:eduuh/bits-and-atoms.git"
            )
        fi
    fi

    echo "Cloning ${#REPOSITORIES[@]} repositories in parallel..."
    for REPO in "${REPOSITORIES[@]}"; do
        _clone_single_repo "$REPO" &
    done
    wait
    echo "All repository clones finished."
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

install_neovim() {
    echo "Installing Neovim from GitHub releases..."
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"

    local arch=$(uname -m)
    local tarball="nvim-linux-${arch}.tar.gz"
    local url="https://github.com/neovim/neovim/releases/latest/download/${tarball}"

    if ! curl -sL "$url" -o "/tmp/${tarball}"; then
        track_failure "neovim" "Failed to download Neovim"
        return 1
    fi

    tar -xzf "/tmp/${tarball}" -C /tmp
    cp "/tmp/nvim-linux-${arch}/bin/nvim" "$install_dir/nvim"
    chmod +x "$install_dir/nvim"
    rm -rf "/tmp/${tarball}" "/tmp/nvim-linux-${arch}"

    echo "Neovim $("$install_dir/nvim" --version | head -1) installed to $install_dir"
}

install_fzf() {
    echo "Installing fzf from GitHub releases..."
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"

    local version
    version=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    if [[ -z "$version" ]]; then
        track_failure "fzf" "Failed to fetch fzf version"
        return 1
    fi

    local url="https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-linux_amd64.tar.gz"

    if ! curl -sL "$url" -o /tmp/fzf.tar.gz; then
        track_failure "fzf" "Failed to download fzf"
        return 1
    fi

    tar -xzf /tmp/fzf.tar.gz -C "$install_dir" fzf
    chmod +x "$install_dir/fzf"
    rm -f /tmp/fzf.tar.gz

    echo "fzf $("$install_dir/fzf" --version) installed to $install_dir"
}

install_lazygit() {
    if command -v lazygit &> /dev/null; then
        echo "LazyGit is already installed."
        return 0
    fi

    # macOS: installed via Brewfile, only need the Linux path
    echo "Installing LazyGit..."
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
}

install_zoxide() {
    if command -v zoxide &> /dev/null; then
        echo "zoxide is already installed."
        return 0
    fi

    # macOS: installed via Brewfile, only need the Linux path
    echo "Installing zoxide..."
    if ! curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        track_failure "zoxide" "Failed to install zoxide via install script"
    else
        if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
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

    # macOS: installed via Brewfile, only need the Linux path
    echo "Installing Starship..."
    if ! curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        track_failure "starship" "Failed to install starship"
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

    echo "Stowing dotfiles from $dotfiles_dir..."
    cd "$dotfiles_dir"
    if ! stow --adopt -t "$HOME" .; then
        track_failure "symlinks" "Failed to create symlinks with stow"
    fi
}

setup_git_hooks() {
    echo "Setting up git hooks for all projects..."
    local hook_source="$HOME/projects/dotfiles/.bin/git-hooks/pre-push"

    if [ ! -f "$hook_source" ]; then
        track_failure "git-hooks" "Pre-push hook not found at $hook_source"
        return 0
    fi

    # Bare repos in ~/projects/bare/*.git
    for bare in ~/projects/bare/*.git(N/); do
        local hook_dir="$bare/hooks"
        echo "Installing pre-push hook in $(basename "$bare")..."
        mkdir -p "$hook_dir"
        if ! ln -sf "$hook_source" "$hook_dir/pre-push"; then
            track_failure "git-hooks" "Failed to install hook in $(basename "$bare")"
        fi
    done

    # Regular clones (dotfiles, nvim, personal-notes)
    for project in dotfiles nvim personal-notes; do
        local git_dir=~/projects/"$project"/.git
        if [ -d "$git_dir" ]; then
            local hook_dir="$git_dir/hooks"
            echo "Installing pre-push hook in $project..."
            mkdir -p "$hook_dir"
            if ! ln -sf "$hook_source" "$hook_dir/pre-push"; then
                track_failure "git-hooks" "Failed to install hook in $project"
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
