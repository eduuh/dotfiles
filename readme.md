## Setting Up the dotfiles

> stow is used to manage the dotfiles

## (Automated) Codespaces, WSL (Ubuntu), and Mac

1. Set up GitHub CLI and configure GitHub SSH keys. Make sure to log in to GitHub CLI:

```zsh
bash <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/.bin/gh_keys.sh)
```

2. Set up the development environment:

```zsh
git clone https://github.com/eduuh/dotfiles.git ~/projects/dotfiles && cd ~/projects/dotfiles && ./setup
```

