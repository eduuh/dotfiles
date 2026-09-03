<div align="center">

# dotfiles

[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)](#)
[![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)](#)
[![Zsh](https://img.shields.io/badge/Zsh-F15A24?logo=zsh&logoColor=white)](#)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white)](#)
[![Tmux](https://img.shields.io/badge/Tmux-1BB91F?logo=tmux&logoColor=white)](#)

</div>

## Setup

Fresh machine — one command bootstraps everything:

```bash
curl -fsSL https://raw.githubusercontent.com/eduuh/dotfiles/main/bootstrap.sh | bash
```

It installs `git`/`zsh`, clones dotfiles into the bare + worktree layout
(`~/projects/bare/dotfiles.git` + `~/projects/worktree/dotfiles/main`), then hands
off to the attended `prep.sh` (sudo, GitHub auth) and the unattended `setup.sh`.
Symlinks are always stowed from the `main` worktree, so you can `wt add
feature/x` and edit dotfiles in multiple worktrees without disturbing them.

Already cloned? Run the phases directly from the main worktree:

```bash
cd ~/projects/worktree/dotfiles/main
./prep.sh && ./setup.sh
```

`setup.sh` flags:

| Flag | Effect |
|------|--------|
| `--work` | Also install work-machine tools and clone the work repos (see [Private repo lists](#private-repo-lists)) |
| `--personal` | Also clone the personal-only repos (see [Private repo lists](#private-repo-lists)) |
| `--profile <core\|dev\|desktop>` | Override the profile recorded by `prep.sh` |
| `--force` | Re-run every step, ignoring the cached done-file |
| `reset` | Clear recorded step state and exit |

Python setup (venv + pynvim/requests, and on Ubuntu the `python3.10` /
`python3.10-venv` apt install) is opt-in. Enable it when you need it:

```bash
SETUP_PYTHON=1 ./setup.sh
```

Auto-detects the platform (macOS, Ubuntu, Arch, Fedora, Codespaces) and runs the same `setup.sh` everywhere — only the package backend differs. Fedora uses `dnf`, or on atomic variants (validated on COSMIC Atomic) layers packages with `rpm-ostree`. Changes apply live via `--apply-live` when possible; anything that can't be applied live is layered into the next deployment and finalized on reboot (setup prints a reminder). Configs and symlinks are stowed via [GNU Stow](https://www.gnu.org/software/stow/).

Re-runs are safe. `setup.sh` is resumable — completed tool-install steps are cached (`~/.local/state/dotfiles/done`) and skipped, while package installation always re-runs, so adding a package to the list and re-running `./setup.sh` installs it without redoing everything. Use `./setup.sh --force` to re-run every step from scratch, or `./setup.sh reset` to clear the recorded state.

After setup, optionally run:

```bash
./setup-projects.sh   # Clone project repos (parallel); add --work / --personal
./setup-rust.sh       # Install Rust toolchain
```

Repos that aren't in `REGULAR_CLONE_REPOS` (see
[`.bin/setup/regular-repos.zsh`](.bin/setup/regular-repos.zsh)) land in the bare +
worktree layout (`~/projects/bare`, `~/projects/worktree`) so `wt` and `tat` pick
them up automatically.

On macOS, all Homebrew packages are managed via a [`Brewfile`](Brewfile).

### personal-notes

`personal-notes` is private and everything else hangs off it — the stow tree it
overlays onto `$HOME`, the work/personal repo lists, and the work-tools
installer. So **every** `setup.sh` run clones or pulls it, up front and
synchronously, before anything that reads from it. It is not part of the
deferred background clone, which is skipped once its step is recorded.

It is cloned over **HTTPS, authenticated through `gh`** — not SSH. On a work
machine the only SSH key is usually the work GitHub account's, which cannot see
the repo, so an SSH clone fails with a misleading `Repository not found`. `gh`
already holds the right token:

```bash
gh auth login          # as the account that owns personal-notes
./setup.sh             # clones it, then stows ~/projects/personal-notes/stow/home
```

If a file the stow tree owns already exists as a real file, it is moved aside to
`<file>.bak-<timestamp>` and the stow is retried, instead of GNU Stow aborting
the whole tree.

### Private repo lists

The split is by **visibility, not by category**: a repo GitHub already shows the
world is named here, a private one never is. So this repo's clone list holds the
toolchain plus the public personal projects, while private repo names, URLs and
the per-machine rules for them live in `personal-notes`.

Personal and work repos are both opt-in regardless of where they're listed — a
work machine shouldn't pull your side projects even when their names are public:

```bash
./setup.sh --work                # work tools + work repos
./setup.sh --personal            # personal-only repos
./setup.sh --work --personal     # both
./setup-projects.sh --personal   # repos only (standalone; setup.sh forwards the flags)
```

Each flag enables private hooks in `personal-notes/scripts/`, every one a no-op
when the file is absent:

| Script | Sourced by | Runs |
|---|---|---|
| `setup-work-tools.sh` | `install_work_tools` | `--work` |
| `setup-work-repos.sh` | `clone_repos` | `--work` |
| `setup-personal-repos.sh` | `clone_repos` | `--personal` |

Both run only after personal-notes is on disk, since that's where they live. The
clone step records a marker per **shape** (`projects`, `projects-personal`,
`projects-work`, `projects-personal-work`), so a machine set up plain still runs
the clone the first time you add a flag — rather than skipping it as already done.

The scripts are sourced, so they have `_clone_single_repo`, `_is_wsl`,
`detect_distro`, and the `REGULAR_CLONE_REPOS` / `WINDOWS_CLONE_REPOS` lists in
scope:

```bash
# ~/projects/personal-notes/scripts/setup-work-repos.sh
WORK_REPOS=(
    "git@github.com:my-org/repo-a.git"
    "git@github.com:my-org/repo-b.git"
)
for r in "${WORK_REPOS[@]}"; do
    _clone_single_repo "$r" &
done
wait
```

## Key Tools

- **`tat`** — Tmux session picker (provided by the [`bn`](https://github.com/eduuh/bn) repo, installed via its `install.sh`)
- **`wt`** — Git worktree manager for bare repos (`wt clone`, `wt add`, `wt list`, `wt remove`)
- **`bn`** — Branch notes manager for per-branch task tracking; also owns the tmux config (an external setup repo, no longer a submodule)
- **`ssh-export`** — Copy SSH key setup script to clipboard for bootstrapping new environments
- **Tmux** (`Ctrl+Space` prefix) — keybinding reference now lives in the bn repo: [`workflow/docs/tmux.md`](https://github.com/eduuh/bn/blob/main/workflow/docs/tmux.md)

## Codespaces

Setup auto-detects Codespaces (`$CODESPACES=true`) and adjusts:

- Skips changing default shell to zsh
- Skips Rust, PNPM, Python venv, Starship installs
- Clones `personal-notes` over HTTPS via `gh` (run `gh auth login` first — no SSH key needed)

## What's Managed

| Config | Details |
|--------|---------|
| Shell | zsh, starship, zoxide, fzf |
| Tmux | Sessions, plugins (resurrect + continuum) |
| Terminals | Kitty, Alacritty |
| macOS | AeroSpace, SketchyBar, Kanata (Colemak), skhd |
| Keyboard | Karabiner, Kanata |

## Related

[win-dot](https://github.com/eduuh/win-dot) · [arch-dotfiles](https://github.com/eduuh/arch-dotfiles)
