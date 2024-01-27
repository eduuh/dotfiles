
dofiles config --local status.showUntrackedFiles no
git config --global core.editor "lvim"

# Check if homebrew is installed
if test ! $(which brew); then
  echo "Installing homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update

# Upgrade any already-installed formulae
brew upgrade --all

# Install GNU core utilities (those that come with macOS are outdated)
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum


# no-quarantine since not part of apple developer program
brew install --cask --no-quarantine alacritty

# Install some other useful utilities like `sponge`
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`
brew install gnu-sed --with-default-names
# Install Bash 4
brew install bash
brew install bash-completion2
# Install `wget` with IRI support
brew install wget --with-iri

# Install more recent versions of some macOS tools
brew install grep
brew install openssh
brew install screen

# Install other useful binaries
brew install git
brew install git-lfs
brew install ripgrep
brew install fzf
brew install lua
brew install p7zip
brew install pigz
brew install pv
brew install rename
brew install ssh-copy-id
brew install tree
brew install vbindiff
brew install zopfli
brew install zsh
brew install tmux


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
exit

git config oh-my-zsh.hide-info 1 --global

## Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
