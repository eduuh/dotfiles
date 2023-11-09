# Harmonize
The repo that harmonise all my dot files in Windows, Mac , Linux , WSL and a docker container.

## Setup

Lets use a bare repo approach.

```bash
git clone --bare https://github.com/eduuh/dotfiles "$HOME/.dotfiles"
dotfiles config --local status.showUntrackedFiles no
```

In windows paste the following command to in poweshell to be able to use the function dotfiles in powershell.
```ps

function dotfiles() {
  git --git-dir=$HOME/.dotfiles --work-tree=$HOME $args
}

```

Force checkout the repo in home directory.

```bash
dotfiles checkout --force
```

### windows

```powershell
/windows_setup.ps1
```
