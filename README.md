# Harmonize

Using stow
```bash
git clone git@github.com:eduuh/dotfiles.git
stow --adopt .
```

### Ubuntu Codespace & wsl

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install git -y
sudo apt-get install stow
sudo apt-get install make
sudo apt-get install cmake

sudo add-apt-repository ppa:neovim-ppa/unstable -y
curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -


sudo apt-get install neovim

mkdir ~/.config
cd ~/.config
git clone https://github.com/eduuh/nvim.git

sudo apt-get install fzf -y
sudo apt-get install ripgrep -y
sudo apt-get install tmux -y
sudo apt-get install cmake -y
sudo apt-get install manpages-dev man-db manpages-posix-dev
sudo apt-get install zsh
chsh -s $(which zsh)
curl -sS https://starship.rs/install.sh | sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
sudo apt-get install python3.10-venv
```
