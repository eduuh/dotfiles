# Harmonize

### Windows

```powershell
iex (iwr -useb "https://raw.githubusercontent.com/eduuh/dotfiles/main/windowsetup.ps1")
```

### setup github cli and setup github ssh keys

Make sure to log in github cli.

```bash
bash <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/github_keys.sh)
```

### Codespaces & WSL (Ubuntu)

```bash
zsh <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/wsl.sh)
```

### Setup the dotfiles

```zsh
cd
git clone git@github.com:eduuh/dotfiles.git
cd dotfiles && stow . --adopt
```
