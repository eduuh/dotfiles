#!/bin/zsh

update_system() {
    echo "Updating package list and upgrading installed packages..."
    sudo apt-get update -y && sudo apt-get upgrade -y
    sudo apt-get install software-properties-common -y
}

install_common_packages() {
    echo "Installing common packages..."

    for pkg in "${common_software[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            sudo apt-get install -y "$pkg"
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
            sudo apt-get install -y "$pkg"
        else
            echo "$pkg is already installed."
        fi
    done

    if ! grep -q "deadsnakes/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "Adding deadsnakes PPA for Python versions..."
        sudo add-apt-repository ppa:deadsnakes/ppa -y
    else
        echo "deadsnakes PPA already added."
    fi

    if ! dpkg -s python3.10 &> /dev/null; then
        echo "Installing Python 3.10..."
        sudo apt-get install -y python3.10 python3.10-venv
    else
        echo "Python 3.10 is already installed."
    fi
}

clean_unneeded_software() {
    echo "Cleaning up unneeded software..."
    sudo apt autoremove -y
}

setup_ubuntu() {
    update_system
    install_common_packages
    install_ubuntu_specific_packages

    if [[ $CODESPACES != "true" ]]; then
        install_nvm
    fi
    install_lazygit
    setup_python
    setup_symlinks
}

setup_codespace() {
    update_system
    install_common_packages
    install_codespace_specific_packages
    setup_python
    setup_symlinks
}
