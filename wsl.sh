#!/bin/zsh

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Fail a pipeline if any command errors

# Function to install a package if it's not already installed
install_if_not_installed() {
    local pkg="$1"
    if ! dpkg -s "$pkg" &> /dev/null; then
        echo "Installing $pkg..."
        sudo apt-get install -y "$pkg"
    else
        echo "$pkg is already installed."
    fi
}

# Update and upgrade the system
echo "Updating package list and upgrading installed packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install essential packages
packages=(
    git stow make cmake fzf ripgrep tmux zsh python3.10-venv
    manpages-dev man-db manpages-posix-dev libsecret-1-dev
    gnome-keyring default-jre python3 libgbm-dev
)

for pkg in "${packages[@]}"; do
    install_if_not_installed "$pkg"
done

# Add Neovim PPA and install Neovim
echo "Adding Neovim PPA and installing Neovim..."
if ! command -v nvim &> /dev/null; then
    sudo add-apt-repository ppa:neovim-ppa/unstable -y
    sudo apt-get update -y
    sudo apt-get install -y neovim
else
    echo "Neovim is already installed."
fi

# Install Node.js via Nodesource setup script
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js is already installed."
fi

# Set up Neovim configuration
echo "Setting up Neovim configuration..."
mkdir -p ~/.config
if [ ! -d ~/.config/nvim ]; then
    git clone https://github.com/eduuh/nvim.git ~/.config/nvim
else
    echo "Neovim configuration already exists."
fi

# Set up project directories and clone repositories
echo "Setting up project directories and cloning repositories..."
mkdir -p ~/projects
cd ~/projects

repos=(
    "git@github.com:eduuh/byte_safari.git"   #private  - obsidian
    "git@github.com:eduuh/dotfiles.git"      #public
    "git@github.com:eduuh/notes.git"         #private  - obsidian
)

for repo in "${repos[@]}"; do
    repo_dir="${repo##*/}"
    repo_dir="${repo_dir%.git}"
    if [ ! -d "$repo_dir" ]; then
        git clone "$repo"
    else
        echo "$repo_dir already exists."
    fi
done

# Apply dotfiles using stow
echo "Applying dotfiles using stow..."
cd ~/projects/dotfiles && stow --adopt .

# Change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
else
    echo "zsh is already the default shell."
fi

# Install starship prompt
if ! command -v starship &> /dev/null; then
    echo "Installing Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh
else
    echo "Starship is already installed."
fi

# Install Rust via rustup
if ! command -v rustup &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
    echo "Rust is already installed."
fi

# Install Microsoft Git
if ! dpkg -s microsoft-git &> /dev/null; then
    echo "Installing Microsoft Git..."
    wget -O microsoft-git.deb https://github.com/microsoft/git/releases/download/v2.46.0.vfs.0.0/microsoft-git_2.46.0.vfs.0.0.deb
    sudo dpkg -i microsoft-git.deb
    rm microsoft-git.deb
else
    echo "Microsoft Git is already installed."
fi

# Install NVM and set up Node.js version
if [ -z "$NVM_DIR" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
fi


source ~/.zshrc

if nvm ls | grep -q 'v18.20.4'; then
    echo "Node.js v18.20.4 is already installed."
else
    echo "Installing Node.js v18.20.4..."
    nvm install v18.20.4
fi

nvm install --lts
nvm use v18.20.4
npm install --global yarn

# Configure Git
echo "Configuring Git..."
git config --global http.postBuffer 524288000
git config --global user.name "eduuh"
git config --global user.email "31909722+eduuh@users.noreply.github.com"


# Set up Python virtual environment and install packages
# I need this for vim
echo "Setting up Python virtual environment..."
python3 -m venv ~/.local/state/python3

echo "Activating Python virtual environment..."
source ~/.local/state/python3/bin/activate

echo "Upgrading pip and installing Python packages..."
pip install --upgrade pip
pip install pynvim requests

# Install `atac` using Cargo
if ! command -v atac &> /dev/null; then
    echo "Installing atac with Cargo..."
    cargo install atac
else
    echo "atac is already installed."
fi

# Install `ttyper` using Cargo
if ! command -v ttyper &> /dev/null; then
    echo "Installing ttyper with Cargo..."
    cargo install ttyper
else
    echo "ttyper is already installed."
fi


echo "Setup completed successfully!"
