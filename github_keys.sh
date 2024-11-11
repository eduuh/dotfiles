#!/bin/bash

# Function to handle errors
error_exit() {
    echo "Error: $1"
    exit 1
}

# Function to install required packages for Ubuntu
install_for_ubuntu() {
    sudo apt-get update -y || error_exit "Failed to update package list on Ubuntu"
    sudo apt-get install -y gh zsh openssh-client || error_exit "Failed to install packages on Ubuntu"
}

# Function to install required packages for Arch Linux
install_for_arch() {
    sudo pacman -Syu --noconfirm || error_exit "Failed to update package list on Arch"
    sudo pacman -S --noconfirm github-cli zsh openssh || error_exit "Failed to install packages on Arch"
}

# Function to install required packages for macOS
install_for_macos() {
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Failed to install Homebrew"
    fi
    brew update || error_exit "Failed to update Homebrew"
    brew install gh zsh openssh || error_exit "Failed to install packages on macOS"
}

# Determine the operating system and install the required packages
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

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C "31909722+eduuh@users.noreply.github.com" -f ~/.ssh/id_rsa -N "" || error_exit "Failed to generate SSH key"
fi

# Start the SSH agent and add the key
eval "$(ssh-agent -s)" || error_exit "Failed to start ssh-agent"
ssh-add ~/.ssh/id_rsa || error_exit "Failed to add SSH key to ssh-agent"

# Authenticate with GitHub using gh CLI
if ! gh auth status &>/dev/null; then
    gh auth login -w || error_exit "Failed to authenticate with GitHub using gh CLI"
fi

# Add SSH key to GitHub using gh CLI
gh ssh-key add ~/.ssh/id_rsa.pub --title "Automated Key $(date +'%Y-%m-%d')" || error_exit "Failed to add SSH key to GitHub"

echo "SSH key added to GitHub successfully."

