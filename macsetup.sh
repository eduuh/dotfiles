# Check if homebrew is installed
if test ! $(which brew); then
  echo "Installing homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew upgrade 

softwares=(
  coreutils
  moreutils
  findutils
  bash
  bash-completion2
  wget 
  grep
  openssh
  screen
  git
  git-lfs
  fzf
  lua
  pv
  p7zip
  pigz
  rename
  ssh-copy-id
  tree
  vbindiff
  zopfli
  zsh
  tmux
  gh
  gnu-sed 
  rust
  node
  deno
  bun
)


for software in "${softwares[@]}"
do
  echo "Installing $software"
  brew install "$software"
done


ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum
brew install --cask --no-quarantine  alacritty


fonts_list=(
  font-agave-nerd-font
  font-fira-mono-nerd-font
  font-caskaydia-cove-nerd-font
  font-hack-nerd-font
  font-hurmit-nerd-font
  font-ubuntu-nerd-font
)

brew tap homebrew/cask-fonts

for font in "${fonts_list[@]}"
do
  brew install --cask "$font"
done


git config --local status.showUntrackedFiles no
git config --global core.editor "nvim"
git config oh-my-zsh.hide-info 1 --global

git clone --force https://github.com/eduuh/Nvim_config ~/.config/nvim
