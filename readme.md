<div align="center">

# dotfiles

[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)](#)
[![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)](#)
[![Zsh](https://img.shields.io/badge/Zsh-F15A24?logo=zsh&logoColor=white)](#)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white)](#)
[![Tmux](https://img.shields.io/badge/Tmux-1BB91F?logo=tmux&logoColor=white)](#)

</div>

I keep my shell, terminal and machine setup here so I don't have to rebuild them
by hand on each Linux or macOS machine. Zsh and tmux configs sit alongside a
three-phase installer: bootstrap, interactive prep, then unattended setup.

The installer selects a package backend, filters steps by profile and records
completed tool installs so a failed run can resume. GNU Stow manages symlinks,
with the main worktree as their source.

Start with [Setup](#setup). These are personal configs, not a general-purpose
installer: setup changes your machine and expects access to private companion
repos. The [private repo notes](#personal-notes) explain that dependency.

## Setup

**One command.** Fresh machine to finished install:

```bash
curl -fsSL https://raw.githubusercontent.com/eduuh/dotfiles/main/bootstrap.sh | bash
```

Add `-s -- --personal` after `bash` to also clone personal project repos.
The flag is forwarded through all three phases:

0. **bootstrap** — installs `git`/`zsh`, clones dotfiles into the bare + worktree
   layout (`~/projects/bare/dotfiles.git` + `~/projects/worktree/dotfiles/main`)
1. **prep** *(attended — the only part that talks to you)* — sudo, GitHub sign-in
   + SSH key, profile
2. **setup** *(unattended — walk away)* — packages, tools, stow, and every repo
   clone, including the optional personal list

Symlinks are always stowed from the `main` worktree, so you can `wt add feature/x`
and edit dotfiles in multiple worktrees without disturbing them.

> **Sign in as the account that owns `personal-notes`.** Prep checks for it by name
> and signs it in if it is missing, because being logged in as *some* account is not
> enough — on a work machine gh is usually the work account, which cannot see a
> single private personal repo. gh keeps both accounts, so the work one stays usable.

Already cloned? Same flags, run the phases directly from the main worktree:

```bash
cd ~/projects/worktree/dotfiles/main
./prep.sh                   # chains into setup.sh
```

`prep.sh` takes `--profile`, `--personal`, and `--prep-only` (stop instead
of chaining into setup). Flags other than `--profile` are passed straight through.

`setup.sh` flags — you only need these when re-running a phase by hand:

| Flag | Effect |
|------|--------|
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

Every install also sets up [`eduuh/nvim`](https://github.com/eduuh/nvim), including
Codespaces and the core profile. It clones through `workspan wt`, links
`~/.config/nvim` to the main worktree, and waits for plugins, parsers, and Mason
tools to finish. An existing config is backed up before the link replaces it.
This step runs on every install, independently of the background project clones.

Setup installs [Workspan](https://github.com/eduuh/workspan) as `workspan`, with `ws` as its
short alias and `bn` retained for compatibility. New clones use `bare/workspan.git` and
`worktree/workspan/main`; existing `bn` worktrees are reused without moving them.

`setup.sh` already launches the project clone in the background, so there is nothing
to run after it. These stay available for retrying a phase on its own:

```bash
./setup-projects.sh          # re-run just the repo clones (parallel); --personal is optional
./setup-rust.sh              # install the Rust toolchain
```

Repos that aren't in `REGULAR_CLONE_REPOS` (see
[`.bin/setup/regular-repos.zsh`](.bin/setup/regular-repos.zsh)) land in the bare +
worktree layout (`~/projects/bare`, `~/projects/worktree`) so `wt` and `tat` pick
them up automatically.

On macOS, all Homebrew packages are managed via a [`Brewfile`](Brewfile).

### Claude Desktop

Arch setup installs `claude-desktop`; macOS installs the `claude` Homebrew cask.
Re-run setup to install it on an existing machine, then open Claude from the app
launcher and sign in. Account credentials and application data stay local.

### .NET 11 and Podman

The `dev` and `desktop` profiles install the .NET 11 prerelease SDK pinned in
[`versions.lock`](versions.lock) on Linux, WSL, macOS and Codespaces. Use
`dotnet11`; it lives in `~/.local/share/dotnet11` and leaves any existing
`dotnet` installation unchanged. Re-running setup checks the pinned SDK even
when earlier tool steps are cached.

Platform package setup also installs Podman, without replacing Docker. On macOS,
run `podman machine init` once, then `podman machine start` before using containers.

### Helium browser on Arch

Arch setup installs `helium-browser-bin` and selects Helium as the default browser
on every run. Omarchy's browser keybindings and link routing follow that default.
Brave remains installed so bookmarks and settings can be imported before removing it.

Launch settings are stowed from
[`config/stow/helium/.config/helium-browser-flags.conf`](config/stow/helium/.config/helium-browser-flags.conf):
native Wayland rendering, the system secret store, touchpad history gestures
and overlay scrollbars. Edit that file to persist launch flags across machines.
Browser profiles, cookies, passwords and history remain local and are not stowed.

### Password managers and VPN on Arch

Arch setup keeps 1Password installed and also installs `nordpass-bin` and
`surfshark-client` from the AUR. The NordPass CLI (`np`) comes from
[NordPass's official installer](https://downloads.npass.app/cli/install.sh) and
lives in `~/.local/bin`.

Every setup run checks for the CLI and enables and starts `surfsharkd2.service`
if needed, even when the platform setup step was already completed. Setup
doesn't sign you in or configure a VPN connection.

Open NordPass and Surfshark to sign in. For CLI access, run `np signin` followed
by `np unlock`. Import 1Password items through NordPass settings and verify
them before removing 1Password. Export files are unencrypted; delete them after
the import. VPN connection, auto-connect and kill switch choices stay manual.

### Email notifications on Linux

Arch setup installs Thunderbird. When it's installed, symlink setup adds a
desktop autostart entry so it checks mail after login. On Omarchy, its windows
open on workspace 4 without switching focus.

Add Gmail and Outlook in Thunderbird using Google's and Microsoft's sign-in
pages. New-mail alerts use desktop notifications; keep Thunderbird running to
receive them. Closing its last window stops mail checks. Work or school
Microsoft accounts may require administrator approval. Account settings and
credentials stay local and aren't stowed.

### Hyprland overrides on Omarchy

Personal settings live in
[`config/stow/hypr/.config/hypr/overrides.lua`](config/stow/hypr/.config/hypr/overrides.lua).
The dotfiles-owned entry point loads Omarchy's defaults, existing user files,
theme and saved toggles first, then loads this file last on every reload.
Settings you put here take precedence over Omarchy.

On Omarchy, re-running `./setup.sh` stows this package from the main worktree.
Existing files are backed up before replacement. Other platforms skip it.
Monitor settings remain local in `~/.config/hypr/monitors.lua`; they aren't
copied into this repository.

Omarchy's `hyprland.lua` is a generated regular file pointing to our
`dotfiles.lua` loader. Neither tracked file uses a name that Omarchy refreshes,
so a reset can't write through a symlink into the repository.

Window rules open Surfshark on workspace 5, Spotify on workspace 4, and Kdenlive
and OBS Studio on workspace 2 without switching focus. Arch setup also ensures
Kdenlive and OBS Studio are installed. Existing shortcuts and appearance stay
unchanged. Add only the differences you want, for example:

```lua
hl.config({ general = { gaps_in = 6 } })
```

Use `o.rebind(...)`, not another `o.bind(...)`, when replacing an Omarchy
shortcut. Don't copy upstream defaults into the override file. A setting
pinned here also takes precedence over the corresponding saved Omarchy toggle
on reload.

Apply with `hyprctl reload` and check `hyprctl configerrors`. Avoid
`omarchy refresh hyprland` for routine changes: it's a reset, not a reload.
If you deliberately reset, re-run setup to restore the dotfiles-owned files.

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
overlays onto `$HOME` and the personal repo list. So **every** `setup.sh` run
clones or pulls it, up front and
synchronously, before anything that reads from it. It is not part of the
deferred background clone, which is skipped once its step is recorded.

It is cloned over **HTTPS, authenticated through `gh`** — not SSH. On a work machine
the only SSH key is usually the work GitHub account's, which cannot see the repo, so
an SSH clone fails with a misleading `Repository not found`. The same applies to every
private repo in `PRIVATE_EDUUH_REPOS` (`.bin/setup/common.sh`): each is rewritten to
HTTPS and cloned with a credential helper pinned to the owning account via
`gh auth token -u <account>`. Pinned, not switched — the active account stays
usable, and repos are matched by **owner/name** so other owners are never rerouted.

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

### branch-notes

`bn`'s notes store (`~/projects/branch-notes`) is a private repo, and it is cloned
**before** the `bn` step for a reason that bit a fresh VM: installing bn starts
`bn serve`, which creates that directory itself, and a directory that already
exists is not a clone. Cloned late, the notes would sit in a plain local folder
with no remote and never sync anywhere.

If the directory is already there without a `.git` (a machine set up before this
existed), setup adopts it: it clones alongside, moves the local files in — repo
version winning, the local copy kept as `<name>.local-<timestamp>` — and swaps
the clone into place.

### Private repo lists

The split is by **visibility, not by category**: a repo GitHub already shows the
world is named here, a private one never is. So this repo's clone list holds the
toolchain plus the public personal projects, while private repo names, URLs and
the per-machine rules for them live in `personal-notes`.

Personal project repos are opt-in regardless of where they're listed:

Pass them to the one-command install and they reach every phase. These forms are for
re-running a phase by hand:

```bash
./setup.sh --personal            # personal-only repos
./setup-projects.sh --personal   # repos only (standalone; setup.sh forwards the flag)
```

The flag enables `personal-notes/scripts/setup-personal-repos.sh` after
personal-notes is on disk; a missing script is a no-op. The clone step records
separate `projects` and `projects-personal` markers, so a machine set up plain
still runs the clone the first time you add `--personal`.

The script is sourced, so it has `_clone_single_repo`, `_is_wsl`,
`detect_distro`, and the `REGULAR_CLONE_REPOS` / `WINDOWS_CLONE_REPOS` lists in
scope:

```bash
# ~/projects/personal-notes/scripts/setup-personal-repos.sh
PERSONAL_REPOS=(
    "git@github.com:my-user/repo-a.git"
    "git@github.com:my-user/repo-b.git"
)
for r in "${PERSONAL_REPOS[@]}"; do
    _clone_single_repo "$r" &
done
wait
```

## Key Tools

- **`tat`** — Tmux session picker (provided by the [`bn`](https://github.com/eduuh/bn) repo, installed via its `install.sh`)
- **`wt`** — Git worktree manager for bare repos (`wt clone`, `wt add`, `wt list`, `wt remove`)
- **`bn`** — Branch notes manager for per-branch task tracking; also owns the tmux config (an external setup repo, no longer a submodule)
- **`ssh-export`** — Copy SSH key setup script to clipboard for bootstrapping new environments
- **Tmux** (`Ctrl+Space` prefix) — keybinding reference now lives in the bn repo: [`config/workflow/docs/tmux.md`](https://github.com/eduuh/bn/blob/main/config/workflow/docs/tmux.md)

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
| Keyboard | Keyflow (Linux/Windows), Kanata and Karabiner (macOS) |

Linux uses a separately provisioned `keyflow.service` with an explicitly selected
keyboard. Dotfiles setup no longer installs or reactivates Kanata on Linux.
The `keyflow` wrapper manages an existing service; it does not install one or
grant broad input-device access. macOS keeps its Kanata layout and setup.

## Related

[win-dot](https://github.com/eduuh/win-dot) · [arch-dotfiles](https://github.com/eduuh/arch-dotfiles)
