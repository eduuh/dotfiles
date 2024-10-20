#!/bin/bash

# Function to install required packages for Ubuntu
install_for_ubuntu() {
    sudo apt-get update -y
    sudo apt-get install -y gh zsh openssh-client
}

# Function to install required packages for Arch Linux
install_for_arch() {
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm github-cli zsh openssh
}

# Check for the distribution and call the corresponding function
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" || "$ID_LIKE" == "debian" ]]; then
        install_for_ubuntu
    elif [[ "$ID" == "arch" ]]; then
        install_for_arch
    else
        echo "Unsupported distribution: $ID"
        exit 1
    fi
else
    echo "/etc/os-release not found. Unable to determine the OS."
    exit 1
fi

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C "31909722+eduuh@users.noreply.github.com"
fi

# Start the SSH agent and add the key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Authenticate with GitHub using gh CLI
gh auth refresh -h github.com -s admin:public_key

# Add SSH key to GitHub using gh CLI
gh ssh-key add ~/.ssh/id_rsa.pub --title "Automated Key $(date +'%Y-%m-%d')"

echo "SSH key added to GitHub successfully."

