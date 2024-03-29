
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

# Remove outdated versions from the cellar
brew cleanup

# Install homebrew cask
brew cask

brew cask install iterm2
brew c
