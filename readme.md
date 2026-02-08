<div align="center">

# dotfiles

**My personal development environment configuration**

[![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)](#)
[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)](#)
[![Zsh](https://img.shields.io/badge/Zsh-F15A24?logo=zsh&logoColor=white)](#)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white)](#)

</div>

---

## Quick Start

```bash
git clone https://github.com/eduuh/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles && ./setup.sh
```

> Handles GitHub auth, SSH keys, and symlinks via [GNU Stow](https://www.gnu.org/software/stow/)

## Documentation

- [Tmux Workflow](docs/tmux.md)

## Private Configuration

Claude Code config is managed separately in a private repo:

```bash
cd ~/projects/personal-notes/stow/home && stow --adopt -t "$HOME" .
```

## Related

| Platform | Repository |
|----------|------------|
| Windows | [eduuh/win-dot](https://github.com/eduuh/win-dot) |
| Archive | [eduuh/arch-dotfiles](https://github.com/eduuh/arch-dotfiles) |
| Trading | [eduuh/thetrader](https://github.com/eduuh/thetrader) |
