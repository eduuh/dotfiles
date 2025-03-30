#!/bin/bash

error_exit() {
    echo "Error: $1"
    exit 1
}

install_for_ubuntu() {
    sudo apt-get update -y || error_exit "Failed to update package list on Ubuntu"
    sudo apt-get install -y gh zsh openssh-client || error_exit "Failed to install packages on Ubuntu"
}

install_for_arch() {
    sudo pacman -Syu --noconfirm || error_exit "Failed to update package list on Arch"
    sudo pacman -S --noconfirm github-cli zsh openssh || error_exit "Failed to install packages on Arch"
}

install_for_macos() {
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Failed to install Homebrew"
    fi
    brew update || error_exit "Failed to update Homebrew"
    brew install gh zsh openssh || error_exit "Failed to install packages on macOS"
}

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" || "$ID_LIKE" == "debian" ]]; then
        install_for_ubuntu
    elif [[ "$ID" == "arch" ]]; then
        install_for_arch
    else
        error_exit "Unsupported Linux distribution: $ID"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    install_for_macos
else
    error_exit "Unsupported operating system: $OSTYPE"
fi

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C "31909722+eduuh@users.noreply.github.com" -f ~/.ssh/id_rsa -N "" || error_exit "Failed to generate SSH key"
fi

eval "$(ssh-agent -s)" || error_exit "Failed to start ssh-agent"
ssh-add ~/.ssh/id_rsa || error_exit "Failed to add SSH key to ssh-agent"

if ! gh auth status &>/dev/null; then
    gh auth login -w || error_exit "Failed to authenticate with GitHub using gh CLI"
fi

gh ssh-key add ~/.ssh/id_rsa.pub --title "Automated Key $(date +'%Y-%m-%d')" || error_exit "Failed to add SSH key to GitHub"

echo "SSH key added to GitHub successfully."

