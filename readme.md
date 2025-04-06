## Setting Up the dotfiles

## (Automated Script) Codespaces, WSL (Ubuntu), and Mac

1. Set up GitHub CLI and configure GitHub SSH keys. Make sure to log in to GitHub CLI:

```zsh
bash <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/.bin/gh_keys.sh)
```

2. Set up the development environment:

```zsh
zsh <(curl -sL https://raw.githubusercontent.com/eduuh/dotfiles/main/.bin/setup.sh)
```

## Manual

- using stow

```zsh
stow . --adopt -t ~

# ignore some files: Codespce command 

stow . -t ~ --ignore='.zshrc' --ignore='.zshenv' --ignore='.bashrc' --ignore='.gitconfig' --ignore='.fzf.bash' --ignore='.fzf.zsh' --ignore='.zprof
ile'

```
