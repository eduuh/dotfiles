#!/bin/zsh

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Fail a pipeline if any command errors

# Detect distribution type
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "Unknown"
    fi
}

# Ubuntu/Debian package installation function
install_packages_ubuntu() {
    echo "Updating package list and upgrading installed packages..."
    sudo apt-get update -y && sudo apt-get upgrade -y

    local packages=(
        git stow make cmake fzf ripgrep tmux zsh python3.10-venv
        manpages-dev man-db manpages-posix-dev libsecret-1-dev
        gnome-keyring default-jre python3 libgbm-dev unzip
    )

    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            sudo apt-get install -y "$pkg"
        else
            echo "$pkg is already installed."
        fi
    done

    install_neovim_ubuntu
}

# Install Neovim on Ubuntu/Debian
install_neovim_ubuntu() {
    echo "Adding Neovim PPA and installing Neovim..."
    if ! command -v nvim &> /dev/null; then
        sudo apt-add-repository ppa:neovim-ppa/stable -y
        sudo apt-get update -y
        sudo apt-get install neovim -y
    else
        echo "Neovim is already installed."
    fi
}

# Arch Linux package installation function
install_packages_arch() {
    echo "Updating package list and upgrading installed packages..."
    yay -Syu --noconfirm

    # Define packages to install
    local packages=(
        git stow make cmake fzf ripgrep tmux zsh python python-vi
        man-db man-pages libsecret gnome-keyring jdk-openjdk unzip brave-bin acpi qmk-git obsidian
    )

    # Loop through each package and install if not already present
    for pkg in "${packages[@]}"; do
        if ! yay -Qi "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            yay -S --noconfirm "$pkg"
        else
            echo "$pkg is already installed."
        fi
    done

    install_neovim_arch
    install_tmux_tpm
}

# Install yay on Arch Linux
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Installing yay AUR helper..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    else
        echo "yay is already installed."
    fi
}

install_tmux_tpm() {
    echo "Checking if TPM is already installed..."
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

# Install Neovim on Arch Linux using yay
install_neovim_arch() {
    echo "Installing Neovim..."
    if ! command -v nvim &> /dev/null; then
        yay -S --noconfirm neovim
    else
        echo "Neovim is already installed."
    fi
}

# Main function to handle distro detection and installation
main() {
    local distro=$(detect_distro)

    case "$distro" in
        ubuntu|debian)
            echo "Detected Ubuntu/Debian"
            install_packages_ubuntu
            ;;
        arch)
            echo "Detected Arch Linux"
            install_packages_arch
            ;;
        *)
            echo "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
}

# Run the main function
main

