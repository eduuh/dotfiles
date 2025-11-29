## Dotfiles Setup Guide

These dotfiles help you quickly configure a consistent development environment across Linux (Arch), macOS, and Windows systems.

### Prerequisites

- [GNU Stow](https://www.gnu.org/software/stow/) (for managing symlinks)
- [GitHub CLI](https://cli.github.com/) (for authentication)


### 1. Set Up GitHub CLI and SSH Keys

Make sure you are logged in to GitHub CLI and have SSH keys set up:

```zsh
bash <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/.bin/gh_keys.sh)
```


### 2. Clone and Set Up Dotfiles (Linux/macOS)

```zsh
git clone https://github.com/eduuh/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles
./setup.sh
```

> **Note:** Skip this step if you are using WSL.

### 3. Windows Setup

For Windows, use the dedicated repository:

https://github.com/eduuh/win-dot

### 4. Archived Repository

Old dotfiles repository (for reference):

https://github.com/eduuh/arch-dotfiles.git

