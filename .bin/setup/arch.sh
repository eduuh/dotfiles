#!/bin/zsh
# Arch Linux specific installation routines

###########################################
# Package manager setup
###########################################

install_yay() {
    if command -v yay &> /dev/null; then
        echo "Yay AUR helper is already installed."
        return 0
    fi

    echo "Installing Yay AUR helper..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd - > /dev/null
    rm -rf /tmp/yay

    echo "Yay AUR helper installed successfully."
}

###########################################
# Package installation functions
###########################################

install_common_packages_arch() {

    common_software=(
        git stow make cmake fzf ripgrep tmux zsh unzip lua curl 1password
    )

    echo "Installing common packages..."

    for pkg in "${common_software[@]}"; do
        if ! yay -Qi "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            yay -S --noconfirm "$pkg"
        else
            echo "$pkg is already installed."
        fi
    done
}

install_arch_specific_packages() {
    echo "Installing Arch-specific packages..."

    # Additional packages specific to Arch Linux
    local arch_packages=(
        man-db man-pages libsecret acpi d2 starship neovim bat
    )

    for pkg in "${arch_packages[@]}"; do
        if ! yay -Qi "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            yay -S --noconfirm "$pkg"
        else
            echo "$pkg is already installed."
        fi
    done
}

install_neovim_arch() {
    echo "Setting up Neovim..."

    if command -v nvim &> /dev/null; then
        echo "Neovim is already installed."
        return 0
    fi

    echo "Installing Neovim..."
    yay -S --noconfirm neovim
}

# Main setup function for Arch Linux
setup_arch() {
    install_yay
    install_nvm
    install_common_packages_arch
    install_arch_specific_packages
    install_neovim_arch

    install_lazygit
    setup_python
    setup_symlinks
}
