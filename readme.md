## Setting Up the dotfiles

## (Automated) Codespaces, WSL (Ubuntu), and Mac

1. Set up GitHub CLI and configure GitHub SSH keys. Make sure to log in to GitHub CLI:

```zsh
bash <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/.bin/gh_keys.sh)
```

2. Set up the development environment:

```zsh
zsh <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/setup.sh)
```

## Manual

- using stow

```zsh
stow . --adopt -t ~

```
