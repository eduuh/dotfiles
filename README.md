## Setup the dotfiles.

### Windows

```powershell
iex (iwr -useb "https://raw.githubusercontent.com/eduuh/dotfiles/main/windowsetup.ps1")
```

### Codespaces & WSL (Ubuntu) & Mac

Setup github cli and setup github ssh keys. Make sure to log in github cli.

```zsh
bash <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/github_keys.sh)
zsh <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/setup.sh)
cd
git clone git@github.com:eduuh/dotfiles.git
cd dotfiles && stow . --adopt
```
