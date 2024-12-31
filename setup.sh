#!/bin/zsh

set -e  
set -o pipefail

common_software=(
    git stow make cmake fzf ripgrep tmux zsh unzip python3
)

detect_distro() {
    if [ "$CODESPACES" = "true" ]; then
        echo "codespace"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ "$(uname)" = "Darwin" ]; then
        echo "darwin"
    else
        echo "Unknown"
    fi
}

install_common_software() {
    local installer="$1"
    local install_cmd="$2"

    for pkg in "${common_software[@]}"; do
        echo "Installing $pkg..."
        $install_cmd "$pkg"
    done
}

install_lazy_Git() {
  echo "Install lazygit"
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
  sudo rm -rf lazygit lazygit.tar.gz
}

update_and_upgrade() {
    echo "Updating package list and upgrading installed packages..."
    sudo apt-get update -y && sudo apt-get upgrade -y
    sudo apt-get install software-properties-common -y
}

install_starship() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping Starship installation."
    elif command -v starship &> /dev/null; then
        echo "Starship is already installed!"
    else
        echo "Starship is not installed. Installing now..."
        curl -sS https://starship.rs/install.sh | sh
    fi
}

install_common_packages() {
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
    local ubuntu_packages=(
        manpages-dev man-db manpages-posix-dev zoxide
        libsecret-1-dev gnome-keyring default-jre libgbm-dev python3-pip
    )

    if [[ $CODESPACES == "true" ]]; then
        sudo apt-get install python3.10-venv -y
    else
        sudo apt-get install python3.12-venv -y
    fi

    for pkg in "${ubuntu_packages[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            sudo apt-get install -y "$pkg"
        else
            echo "$pkg is already installed."
        fi
    done
}

install_nvm() {
    echo "Installing NVM and Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install --lts
}

setup_python_environment() {
    echo "Setting up Python environment..."
    python3 -m venv ~/.local/state/python3
    source ~/.local/state/python3/bin/activate
    pip install --upgrade pip pynvim requests
}

clean_unneeded_software() {
    echo "Cleaning up unneeded software..."
    sudo apt autoremove
}

setup_dotfiles() {
    echo "Setting up dotfiles symlinks..."
    cd ~/projects/dotfiles/
    
    if [[ $CODESPACES == "true" ]]; then
        stow . -t ~ --ignore='.zshrc' --ignore='.zshenv' --ignore='.bashrc' --ignore='.gitconfig'
    else
        stow . --adopt -t ~
    fi
}
# Install Neovim on Ubuntu/Debian
install_neovim_ubuntu() {
    echo "Adding Neovim PPA and installing Neovim..."
    
    if ! command -v nvim &> /dev/null; then
        sudo add-apt-repository ppa:neovim-ppa/unstable -y
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
    brew install jesseduffield/lazydocker/lazydocker

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

clone_repositories() {
  cd ~
  
  if [ ! -d ~/projects ]; then
    mkdir ~/projects
  fi

  if [ "$CODESPACES" = "true" ]; then
      REPOSITORIES=(
          "https://github.com/eduuh/nvim.git"
          "https://github.com/eduuh/dotfiles.git"
      )
  else
      REPOSITORIES=(
          "git@github.com:eduuh/byte_safari.git"
          "git@github.com:eduuh/keyboard.git"
          "git@github.com:eduuh/dushg.git"
          "git@github.com:eduuh/homelab.git"
          "git@github.com:eduuh/nvim.git"
          "git@github.com:eduuh/dotfiles.git"
      )
  fi
    
  for REPO in "${REPOSITORIES[@]}"; do
      REPO_NAME=$(basename "$REPO" .git)
      TARGET_DIR=~/projects/"$REPO_NAME"

      if [[ "$REPO_NAME" == "nvim" ]]; then
          if [ ! -d "$TARGET_DIR" ]; then
              echo "Cloning $REPO_NAME into $TARGET_DIR..."
              git clone "$REPO" "$TARGET_DIR"
          fi
          
          echo "Creating symbolic link for $REPO_NAME at ~/.config/nvim..."
          sudo ln -sf "$TARGET_DIR" ~/.config/nvim
      else
          if [ -d "$TARGET_DIR" ]; then
              echo "Skipping $REPO_NAME: Already exists at $TARGET_DIR."
          else
              echo "Cloning $REPO_NAME into $TARGET_DIR..."
              git clone "$REPO" "$TARGET_DIR"
          fi
      fi
  done
}

install_packages_ubuntu() {
    update_and_upgrade
    install_starship
    install_common_packages
    install_ubuntu_specific_packages

    if [[ $CODESPACES != "true" ]]; then
      install_nvm
    fi

    install_neovim_ubuntu
    install_lazy_Git
    setup_python_environment
    clean_unneeded_software
    setup_dotfiles
}

main() {
    local distro=$(detect_distro)

    case "$distro" in
        ubuntu|debian)
            echo "Detected Ubuntu/Debian"
            clone_repositories
            install_packages_ubuntu
            sudo chsh -s /bin/zsh
            ;;
        arch)
            echo "Detected Arch Linux"
            install_yay
            clone_repositories
            install_packages_arch
            ;;
        codespace)
            echo "Detected Codespace environment"
            clone_repositories
            install_packages_ubuntu
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
