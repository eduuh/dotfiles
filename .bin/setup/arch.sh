#!/bin/zsh

add_kanatakeyboardprev() {
  current_user=$(whoami)

  kanata_path="/home/$current_user/.bin/kanata"

  if ! sudo grep -q "$kanata_path" /etc/sudoers; then
    echo "$current_user ALL=(ALL) NOPASSWD: $kanata_path" | sudo tee -a /etc/sudoers > /dev/null
    echo "Sudoers entry added for $current_user to run $kanata_path without a password."
  else
    echo "Sudoers entry already exists for $current_user."
  fi

  systemctl --user enable kanata.service
  systemctl --user start kanata.service
}

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

install_common_packages_arch() {
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

    local arch_packages=(
        man-db man-pages libsecret acpi d2 bat lua curl kanata 1password
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
