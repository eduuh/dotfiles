#!/bin/zsh

add_kanatakeyboardprev() {
    local current_user=$(whoami)
    local kanata_path="/home/$current_user/.bin/kanata"

    if ! sudo grep -q "$kanata_path" /etc/sudoers; then
        if ! echo "$current_user ALL=(ALL) NOPASSWD: $kanata_path" | sudo tee -a /etc/sudoers > /dev/null; then
            track_failure "kanata" "Failed to add sudoers entry for kanata"
            return 0
        fi
        echo "Sudoers entry added for $current_user to run $kanata_path without a password."
    else
        echo "Sudoers entry already exists for $current_user."
    fi

    if ! systemctl --user enable kanata.service; then
        track_failure "kanata" "Failed to enable kanata service"
    fi
    if ! systemctl --user start kanata.service; then
        track_failure "kanata" "Failed to start kanata service"
    fi
}

install_yay() {
    if command -v yay &> /dev/null; then
        echo "Yay AUR helper is already installed."
        return 0
    fi

    echo "Installing Yay AUR helper..."
    if ! sudo pacman -S --needed --noconfirm git base-devel; then
        track_failure "pacman" "Failed to install git and base-devel"
        return 0
    fi

    if ! git clone https://aur.archlinux.org/yay.git /tmp/yay; then
        track_failure "yay" "Failed to clone yay repository"
        return 0
    fi

    cd /tmp/yay
    if ! makepkg -si --noconfirm; then
        cd - > /dev/null
        rm -rf /tmp/yay
        track_failure "yay" "Failed to build and install yay"
        return 0
    fi
    cd - > /dev/null
    rm -rf /tmp/yay
    echo "Yay AUR helper installed successfully."
}

install_common_packages_arch() {
    echo "Installing common packages..."

    for pkg in "${common_software[@]}"; do
        if ! yay -Qi "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            if ! yay -S --noconfirm "$pkg"; then
                track_failure "yay" "Failed to install: $pkg"
            fi
        else
            echo "$pkg is already installed."
        fi
    done
}

install_arch_specific_packages() {
    echo "Installing Arch-specific packages..."

    local arch_packages=(
        man-db man-pages libsecret acpi d2 bat lua curl kanata 1password
    )

    for pkg in "${arch_packages[@]}"; do
        if ! yay -Qi "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            if ! yay -S --noconfirm "$pkg"; then
                track_failure "yay" "Failed to install: $pkg"
            fi
        else
            echo "$pkg is already installed."
        fi
    done
}

setup_arch() {
    install_yay
    install_nvm
    install_common_packages_arch
    install_arch_specific_packages

    install_lazygit
    install_claude_code
    setup_python
    setup_symlinks
    add_kanatakeyboardprev
}
