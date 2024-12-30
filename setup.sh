#!/bin/zsh

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Fail a pipeline if any command errors

# Global list of common software packages for all OSes
common_software=(
    git stow make cmake fzf ripgrep tmux zsh unzip python3
)

# Detect distribution type
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ "$(uname)" = "Darwin" ]; then
        echo "darwin"
    else
        echo "Unknown"
    fi
}

# Install common software packages
install_common_software() {
    local installer="$1"
    local install_cmd="$2"

    for pkg in "${common_software[@]}"; do
        echo "Installing $pkg..."
        $install_cmd "$pkg"
    done
}



# Ubuntu/Debian package installation function
install_packages_ubuntu() {
    echo "Updating package list and upgrading installed packages..."
    sudo apt-get update -y && sudo apt-get upgrade -y

     if command -v starship &> /dev/null; then
        echo "Starship is already installed!"
      else
	 echo "Starship is not installed. Installing now..."
	 curl -sS https://starship.rs/install.sh | sh
      fi

    for pkg in "${common_software[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            sudo apt-get install -y "$pkg"
        else
            echo "$pkg is already installed."
        fi
    done

    # Additional packages specific to Ubuntu/Debian
    local ubuntu_packages=(
        manpages-dev man-db manpages-posix-dev zoxide
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

    install_neovim_ubuntu
}

# Install Neovim on Ubuntu/Debian
install_neovim_ubuntu() {
    echo "Adding Neovim PPA and installing Neovim..."
    if ! command -v nvim &> /dev/null; then
        sudo add-apt-repository ppa:neovim-ppa/unstable
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

    install_common_software "yay" "yay -S --noconfirm"

    # Additional packages specific to Arch Linux
    local arch_packages=(
        man-db man-pages libsecret gnome-keyring jdk-openjdk
        brave-bin acpi qmk-git obsidian deno mermaid-cli d2
        plantuml imagemagick
    )

    for pkg in "${arch_packages[@]}"; do
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

# Homebrew and software installation for macO
install_homebrew_mac() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    brew update
    brew upgrade

    for software in "${common_software[@]}"; do
        echo "Installing $software..."
        brew install "$software"
    done

    # Additional software for macOS
    local mac_software=(
        coreutils moreutils findutils bash bash-completion2 wget
        openssh screen git-lfs lua pv p7zip pigz rename ssh-copy-id
        vbindiff zopfli gnu-sed rust node deno hugo lazygit bat zoxide
        fish kitty sha256sum imagemagick pkg-config pngpaste
        brave-browser
    )

    for software in "${mac_software[@]}"; do
        echo "Installing $software..."
        brew install "$software"
    done

    # Cask installations for macOS
    local mac_casks=(
        alacritty karabiner-elements kitty@nightly
    )

    for cask in "${mac_casks[@]}"; do
        echo "Installing $cask..."
        brew install --cask "$cask"
    done

    # Install TPM
    brew install tpm

    # Font installation for macOS
    brew tap homebrew/cask-fonts
    brew tap julien-cpsn/atac

    local fonts_list=(
        font-agave-nerd-font font-fira-mono-nerd-font font-caskaydia-cove-nerd-font
        font-hack-nerd-font font-hurmit-nerd-font font-ubuntu-nerd-font atac
    )

    for font in "${fonts_list[@]}"; do
        echo "Installing font $font..."
        brew install --cask "$font"
    done

    # Python environment setup
    brew install pyenv
    pyenv install 3.12.0
    pyenv global 3.12.0
    python3 -m venv ~/.local/state/python3
    source ~/.local/state/python3/bin/activate
    pip install --upgrade pip pynvim requests

    # ATAC installation
    brew tap julien-cpsn/atac
    brew install atac

    # Enable third-party application support
    sudo spctl --master-disable

    curl -fsSL https://bun.sh/install | bash
}

# Main function to handle OS detection and installation

clone_repositories() {
  cd ~
  
  # Ensure the ~/projects directory exists
  if [ ! -d ~/projects ]; then
    mkdir ~/projects
  fi

  # List of repositories to clone
  REPOSITORIES=(
    "git@github.com:eduuh/byte_safari.git"
    "git@github.com:eduuh/keyboard.git"
    "git@github.com:eduuh/dushg.git"
    "git@github.com:eduuh/homelab.git"
    "git@github.com:eduuh/nvim.git"
    "git@github.com:eduuh/dotfiles.git"
  )
    
  # Clone each repository
  for REPO in "${REPOSITORIES[@]}"; do
      # Extract the repository name
      REPO_NAME=$(basename "$REPO" .git)
      TARGET_DIR=~/projects/"$REPO_NAME"

      # Handle special case for NVIM and create a symbolic link
      if [[ "$REPO_NAME" == "nvim" ]]; then
          # Clone the repository if it doesn't already exist
          if [ ! -d "$TARGET_DIR" ]; then
              echo "Cloning $REPO_NAME into $TARGET_DIR..."
              git clone "$REPO" "$TARGET_DIR"
          fi
          
          # Create a symbolic link to the nvim configuration directory
          echo "Creating symbolic link for $REPO_NAME at ~/.config/nvim..."
          sudo ln -sf "$TARGET_DIR" ~/.config/nvim
      else
          # Clone other repositories normally
          if [ -d "$TARGET_DIR" ]; then
              echo "Skipping $REPO_NAME: Already exists at $TARGET_DIR."
          else
              echo "Cloning $REPO_NAME into $TARGET_DIR..."
              git clone "$REPO" "$TARGET_DIR"
          fi
      fi
  done
}

main() {
    local distro=$(detect_distro)

    case "$distro" in
        ubuntu|debian)
            echo "Detected Ubuntu/Debian"
            clone_repositories
            install_packages_ubuntu
            ;;
        arch)
            echo "Detected Arch Linux"
            install_yay
            clone_repositories
            install_packages_arch
            ;;
        darwin)
            echo "Detected macOS"
            clone_repositories
               # Hide Dock
            sudo launchctl unload -w /System/Library/LaunchAgents/com.apple.Dock.plist
            install_homebrew_mac
            ;;
        *)
            echo "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
}


main
