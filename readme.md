## Dotfiles Setup Guide

These dotfiles help you quickly configure a consistent development environment across Linux (Arch), macOS, and Windows systems.

### Prerequisites

- [GNU Stow](https://www.gnu.org/software/stow/) (for managing symlinks)
- [GitHub CLI](https://cli.github.com/) (for authentication) - *Installed automatically by setup script*


### 1. Clone and Set Up Dotfiles (Linux/macOS)

```zsh
git clone https://github.com/eduuh/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles
./setup.sh
```

The setup script will handle GitHub authentication and SSH key generation.

> **Note:** Skip this step if you are using WSL.

### 3. Windows Setup

For Windows, use the dedicated repository:

https://github.com/eduuh/win-dot

### 4. Archived Repository

Old dotfiles repository (for reference):

https://github.com/eduuh/arch-dotfiles.git

