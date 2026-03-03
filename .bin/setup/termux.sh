#!/bin/zsh
# Termux (Android) setup — no sudo, uses pkg

update_system() {
    echo "Updating pkg..."
    if ! pkg update -y; then
        track_failure "pkg" "Failed to update package list"
    fi
    if ! pkg upgrade -y; then
        track_failure "pkg" "Failed to upgrade packages"
    fi
}

install_common_packages() {
    echo "Installing common packages..."
    # Termux package names that map to common_software
    local termux_packages=(
        git stow ripgrep tmux zsh unzip tree jq make cmake
    )
    for p in "${termux_packages[@]}"; do
        if ! pkg list-installed 2>/dev/null | grep -q "^$p/"; then
            echo "Installing $p..."
            if ! pkg install -y "$p"; then
                track_failure "pkg" "Failed to install: $p"
            fi
        else
            echo "$p is already installed."
        fi
    done
}

install_termux_specific_packages() {
    echo "Installing Termux-specific packages..."
    local packages=(fzf zoxide starship neovim lazygit)
    for p in "${packages[@]}"; do
        if ! pkg list-installed 2>/dev/null | grep -q "^$p/"; then
            echo "Installing $p..."
            if ! pkg install -y "$p"; then
                track_failure "pkg" "Failed to install: $p"
            fi
        else
            echo "$p is already installed."
        fi
    done
}

setup_termux() {
    update_system
    install_common_packages
    install_termux_specific_packages
    install_tmux_plugins
    change_shell_to_zsh
    setup_symlinks
}
