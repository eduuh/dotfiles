#!/bin/zsh

update_system() {
    echo "Updating package list and upgrading installed packages..."
    if ! sudo apt-get update -y; then
        track_failure "apt" "Failed to update package list"
    fi
    if ! sudo apt-get upgrade -y; then
        track_failure "apt" "Failed to upgrade packages"
    fi
    if ! sudo apt-get install software-properties-common -y; then
        track_failure "apt" "Failed to install software-properties-common"
    fi
}

install_common_packages() {
    echo "Installing common packages..."

    for pkg in "${common_software[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            if ! sudo apt-get install -y "$pkg"; then
                track_failure "apt" "Failed to install: $pkg"
            fi
        else
            echo "$pkg is already installed."
        fi
    done
}

install_ubuntu_specific_packages() {
    echo "Installing Ubuntu-specific packages..."

    local ubuntu_packages=(
        manpages-dev man-db manpages-posix-dev
        libsecret-1-dev gnome-keyring default-jre libgbm-dev
    )

    for pkg in "${ubuntu_packages[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            if ! sudo apt-get install -y "$pkg"; then
                track_failure "apt" "Failed to install: $pkg"
            fi
        else
            echo "$pkg is already installed."
        fi
    done

    if ! grep -q "deadsnakes/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "Adding deadsnakes PPA for Python versions..."
        if ! sudo add-apt-repository ppa:deadsnakes/ppa -y; then
            track_failure "apt" "Failed to add deadsnakes PPA"
        fi
    else
        echo "deadsnakes PPA already added."
    fi

    if ! dpkg -s python3.10 &> /dev/null; then
        echo "Installing Python 3.10..."
        if ! sudo apt-get install -y python3.10 python3.10-venv; then
            track_failure "python" "Failed to install Python 3.10"
        fi
    else
        echo "Python 3.10 is already installed."
    fi
}

clean_unneeded_software() {
    echo "Cleaning up unneeded software..."
    sudo apt autoremove -y || track_failure "apt" "Failed to autoremove packages"
}

setup_ubuntu() {
    update_system
    install_common_packages
    ensure_tmux_version
    install_neovim
    install_fzf
    install_ubuntu_specific_packages

    if [[ $CODESPACES != "true" ]]; then
        install_nvm
    fi
    install_lazygit
    install_claude_code
    setup_python
    setup_symlinks
}

setup_codespace() {
    update_system
    install_common_packages
    ensure_tmux_version
    install_neovim
    install_fzf
    install_claude_code
    setup_python
    setup_symlinks
}
