<div align="center">

# dotfiles

[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)](#)
[![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)](#)
[![Zsh](https://img.shields.io/badge/Zsh-F15A24?logo=zsh&logoColor=white)](#)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white)](#)
[![Tmux](https://img.shields.io/badge/Tmux-1BB91F?logo=tmux&logoColor=white)](#)

</div>

## Setup

**One command.** Fresh machine to finished install:

```bash
curl -fsSL https://raw.githubusercontent.com/eduuh/dotfiles/main/bootstrap.sh | bash -s -- --work
```

Choosing the flag is the only decision you make. Everything after it is automatic.

| Machine | Flag |
|---|---|
| Work laptop | `--work` |
| Personal machine | `--personal` |
| Both sides on one box | `--work --personal` |
| Toolchain only | *(omit; run `\| bash` with no `-s --`)* |

The flag is forwarded through all three phases, so there is nothing to re-run
afterwards with a different flag:

0. **bootstrap** — installs `git`/`zsh`, clones dotfiles into the bare + worktree
   layout (`~/projects/bare/dotfiles.git` + `~/projects/worktree/dotfiles/main`)
1. **prep** *(attended — the only part that talks to you)* — sudo, GitHub sign-in
   + SSH key, profile
2. **setup** *(unattended — walk away)* — packages, tools, stow, and every repo
   clone, including the work/personal lists

Symlinks are always stowed from the `main` worktree, so you can `wt add feature/x`
and edit dotfiles in multiple worktrees without disturbing them.

> **Sign in as the account that owns `personal-notes`.** Prep checks for it by name
> and signs it in if it is missing, because being logged in as *some* account is not
> enough — on a work machine gh is usually the work account, which cannot see a
> single private personal repo. gh keeps both accounts, so the work one stays usable.

Already cloned? Same flags, run the phases directly from the main worktree:

```bash
cd ~/projects/worktree/dotfiles/main
./prep.sh --work            # chains into setup.sh, forwarding the flag
```

`prep.sh` takes `--profile`, `--work`, `--personal`, and `--prep-only` (stop instead
of chaining into setup). Flags other than `--profile` are passed straight through.

`setup.sh` flags — you only need these when re-running a phase by hand:

| Flag | Effect |
|------|--------|
| `--work` | Also install work-machine tools and clone the work repos (see [Private repo lists](#private-repo-lists)) |
| `--personal` | Also clone the personal-only repos (see [Private repo lists](#private-repo-lists)) |
| `--profile <core\|dev\|desktop>` | Override the profile recorded by `prep.sh` |
| `--force` | Re-run every step, ignoring the cached done-file |
| `--windows-admin` | *(WSL)* Also run win-dot's elevated `run.ps1` — raises a UAC prompt (see [The Windows side](#the-windows-side)) |
| `--windows-keyboard` | *(WSL)* Also install the Keyflow keyboard layout on Windows |
| `reset` | Clear recorded step state and exit |

Python setup (venv + pynvim/requests, and on Ubuntu the `python3.10` /
`python3.10-venv` apt install) is opt-in. Enable it when you need it:

```bash
SETUP_PYTHON=1 ./setup.sh
```

Auto-detects the platform (macOS, Ubuntu, Arch, Fedora, Codespaces) and runs the same `setup.sh` everywhere — only the package backend differs. Fedora uses `dnf`, or on atomic variants (validated on COSMIC Atomic) layers packages with `rpm-ostree`. Changes apply live via `--apply-live` when possible; anything that can't be applied live is layered into the next deployment and finalized on reboot (setup prints a reminder). Configs and symlinks are stowed via [GNU Stow](https://www.gnu.org/software/stow/).

Re-runs are safe. `setup.sh` is resumable — completed tool-install steps are cached (`~/.local/state/dotfiles/done`) and skipped, while package installation always re-runs, so adding a package to the list and re-running `./setup.sh` installs it without redoing everything. Use `./setup.sh --force` to re-run every step from scratch, or `./setup.sh reset` to clear the recorded state.

`setup.sh` already launches the project clone in the background, so there is nothing
to run after it. These stay available for retrying a phase on its own:

```bash
./setup-projects.sh --work   # re-run just the repo clones (parallel); flags as above
./setup-rust.sh              # install the Rust toolchain
```

Repos that aren't in `REGULAR_CLONE_REPOS` (see
[`.bin/setup/regular-repos.zsh`](.bin/setup/regular-repos.zsh)) land in the bare +
worktree layout (`~/projects/bare`, `~/projects/worktree`) so `wt` and `tat` pick
them up automatically.

On macOS, all Homebrew packages are managed via a [`Brewfile`](Brewfile).

### The Windows side

On WSL, dotfiles configures Linux — but half the machine is Windows, and none of
what a Windows application reads (PowerShell profile, Windows Terminal, GlazeWM,
VS Code, and the `.wslconfig` that sizes the WSL VM) can live in the WSL
filesystem. That half is [`eduuh/win-dot`](https://github.com/eduuh/win-dot), and
`setup.sh` installs it for you:

1. `clone_repos` clones win-dot **onto the Windows filesystem**, at
   `/mnt/c/Users/<you>/projects/win-dot`, and symlinks `~/projects/win-dot` at it
   so `wt`, `tat` and `bn` list it like any other repo. That routing comes from
   naming it in **both** `REGULAR_CLONE_REPOS` and `WINDOWS_CLONE_REPOS` — either
   list alone silently puts the clone inside WSL, where Windows tooling can't
   reach it.
2. The `windows-side` step hands
   [`.bin/setup/windows-side.ps1`](.bin/setup/windows-side.ps1) to `powershell.exe`,
   which installs Scoop and git if missing and then runs win-dot's own
   `scripts/install.ps1` (packages + profile stubs) and `scripts/setup-git.ps1`
   (checks the clone out over `$HOME`, wiring the `dot` command). Idempotent, so
   it reconciles on every run.

Restart PowerShell afterwards to pick up the profile.

**What is *not* automatic.** win-dot's `scripts/run.ps1` — Developer Mode and the
WSL/VirtualMachinePlatform Windows features — needs Administrator. It self-elevates
through UAC and then asks its own Y/N question, so it can't run in setup's
unattended phase, and reaching it from inside WSL means the features it enables are
already on. Run it deliberately if you need it:

```bash
./setup.sh --windows-admin      # accept the UAC prompt, then answer Y
```

A win-dot clone on NTFS gets `core.filemode false` and `core.autocrlf true`, applied
on every run rather than only at clone time. Without the second one, Windows tooling
rewrites the checkout with CRLF, git reports every tracked file as modified, and
`clone_repos`' "unsaved changes" guard then refuses to pull the repo ever again.

### personal-notes

`personal-notes` is private and everything else hangs off it — the stow tree it
overlays onto `$HOME`, the work/personal repo lists, and the work-tools
installer. So **every** `setup.sh` run clones or pulls it, up front and
synchronously, before anything that reads from it. It is not part of the
deferred background clone, which is skipped once its step is recorded.

It is cloned over **HTTPS, authenticated through `gh`** — not SSH. On a work machine
the only SSH key is usually the work GitHub account's, which cannot see the repo, so
an SSH clone fails with a misleading `Repository not found`. The same applies to every
private repo in `PRIVATE_EDUUH_REPOS` (`.bin/setup/common.sh`): each is rewritten to
HTTPS and cloned with a credential helper pinned to the owning account via
`gh auth token -u <account>`. Pinned, not switched — the work account stays gh-active
and usable, and work repos are matched by **owner/name** so they are never rerouted.

Prep signs that account in for you, so normally there is nothing to do. To do it by
hand:

```bash
gh auth login          # as the account that owns personal-notes
./setup.sh             # clones it, then stows ~/projects/personal-notes/stow/home
```

If the account is missing, setup does not guess: it fails the step with the account
it actually found and the command to fix it, rather than letting the clone die with
`Repository not found`.

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

Pass them to the one-command install and they reach every phase. These forms are for
re-running a phase by hand:

```bash
./setup.sh --work                # work tools + work repos
./setup.sh --personal            # personal-only repos
./setup.sh --work --personal     # both
./setup-projects.sh --work       # repos only (standalone; setup.sh forwards the flags)
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
