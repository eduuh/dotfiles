## Setting Up the .files

Before starting the setup, ensure that **1Password** is installed and you are logged in.

### Windows

To set up the dotfiles on Windows, run the following PowerShell command:

```powershell
iex (iwr -useb "https://raw.githubusercontent.com/eduuh/dotfiles/main/windowsetup.ps1")
```

### Codespaces, WSL (Ubuntu), and Mac

1. Set up GitHub CLI and configure GitHub SSH keys. Make sure to log in to GitHub CLI:

```zsh
bash <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/github_keys.sh)
```

2. Set up the development environment:

```zsh
zsh <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/setup.sh)
```
