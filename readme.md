<div align="center">

# dotfiles

[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)](#)
[![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)](#)
[![Zsh](https://img.shields.io/badge/Zsh-F15A24?logo=zsh&logoColor=white)](#)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white)](#)
[![Tmux](https://img.shields.io/badge/Tmux-1BB91F?logo=tmux&logoColor=white)](#)

</div>

## Setup

```bash
git clone https://github.com/eduuh/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles && ./setup.sh
```

Auto-detects platform (macOS, Ubuntu, Arch, Codespaces) and installs packages, configs, and symlinks via [GNU Stow](https://www.gnu.org/software/stow/).

After setup, optionally run:

```bash
./setup-projects.sh   # Clone project repos (parallel)
./setup-rust.sh       # Install Rust toolchain
```

On macOS, all Homebrew packages are managed via a [`Brewfile`](Brewfile).

## Key Tools

- **`tat`** — Tmux session picker with zoxide frecency and fzf preview
- **`wt`** — Git worktree manager for bare repos (`wt clone`, `wt add`, `wt list`, `wt remove`)
- **Tmux** (`Ctrl+Space` prefix) — [keybinding reference](docs/tmux.md)

## What's Managed

| Config | Details |
|--------|---------|
| Shell | zsh, starship, zoxide, fzf |
| Tmux | Sessions, plugins (resurrect + continuum) |
| Terminals | Kitty, Alacritty |
| macOS | AeroSpace, SketchyBar, Kanata (Colemak), skhd |
| Keyboard | Karabiner, Kanata |

## Related

[win-dot](https://github.com/eduuh/win-dot) · [arch-dotfiles](https://github.com/eduuh/arch-dotfiles) · [thetrader](https://github.com/eduuh/thetrader)
