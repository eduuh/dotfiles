#!/bin/zsh

# Pinned tool versions (repo-root versions.lock). ${(%):-%x} resolves this file's
# path even when sourced, so the lock loads regardless of who sources common.sh.
_COMMON_DIR="${${(%):-%x}:A:h}"
[[ -f "$_COMMON_DIR/../../versions.lock" ]] && source "$_COMMON_DIR/../../versions.lock"

# Optional external env vars, defaulted so common.sh is safe under `set -u`. prep.sh sources
# this with `set -u`; an unset reference there aborts the whole source, which would drop
# every function defined below the first such reference (e.g. detect_distro / _is_wsl).
: "${CODESPACES:=}"
: "${TERMUX_VERSION:=}"
: "${WINDOWS_PROJECTS_DIR:=}"

# Failure tracking - collect errors instead of exiting
typeset -ga SETUP_FAILURES=()

track_failure() {
    local component="$1"
    local message="$2"
    SETUP_FAILURES+=("[$component] $message")
    echo "WARNING: $message (continuing...)"
}

# Run a command and track failure if it fails
run_or_track() {
    local component="$1"
    shift
    if ! "$@"; then
        track_failure "$component" "Failed: $*"
        return 1
    fi
    return 0
}

# --- Resumable step runner -------------------------------------------------
# Records completed steps so a re-run skips them and a failed run resumes where
# it stopped. State lives alongside the prep "ready" marker.
SETUP_STATE_DIR="${SETUP_STATE_DIR:-$HOME/.local/state/dotfiles}"
SETUP_DONE_FILE="${SETUP_DONE_FILE:-$SETUP_STATE_DIR/done}"
SETUP_FORCE="${SETUP_FORCE:-false}"

_step_is_done() {
    [[ -f "$SETUP_DONE_FILE" ]] && grep -qxF "$1" "$SETUP_DONE_FILE"
}

_step_mark_done() {
    mkdir -p "$SETUP_STATE_DIR"
    grep -qxF "$1" "$SETUP_DONE_FILE" 2>/dev/null || print -r -- "$1" >> "$SETUP_DONE_FILE"
}

# run_step <name> <command> [args...]
# Runs the command once; skips if already recorded (unless SETUP_FORCE=true).
# Records on SUCCESS only, so a failed step is retried on the next run.
run_step() {
    local name="$1"; shift
    if [[ "$SETUP_FORCE" != "true" ]] && _step_is_done "$name"; then
        echo "✓ [$name] already done — skipping"
        return 0
    fi
    echo "▶ [$name] ..."
    if "$@"; then
        _step_mark_done "$name"
        return 0
    fi
    track_failure "$name" "step '$name' failed"
    return 1
}

# Forget recorded steps so the next run re-does everything.
reset_steps() {
    rm -f "$SETUP_DONE_FILE"
    echo "Cleared step state ($SETUP_DONE_FILE)."
}

# --- Profiles & targets ----------------------------------------------------
# Nested tiers: core ⊂ dev ⊂ desktop. The active PROFILE includes its own tier
# and every tier below it. TARGET is one of codespace|wsl|linux|mac|termux.
# Both come from the prep "ready" marker.
_profile_rank() {
    case "$1" in core) echo 1;; dev) echo 2;; desktop) echo 3;; *) echo 0;; esac
}

# True if the active PROFILE includes tier $1.
_profile_includes() {
    [[ $(_profile_rank "${PROFILE:-desktop}") -ge $(_profile_rank "$1") ]]
}

# True if the active TARGET is in $1 ("all" or a comma list like "linux,mac").
_target_matches() {
    [[ "$1" == "all" ]] && return 0
    local t
    for t in ${(s:,:)1}; do
        [[ "$t" == "${TARGET:-}" ]] && return 0
    done
    return 1
}

# step <name> <min_profile> <targets> <command> [args...]
#   min_profile: core|dev|desktop — run only if the active PROFILE includes it
#   targets:     "all" or csv (e.g. "linux,mac") — run only if TARGET matches
# Passes through to run_step (so it's still idempotent + resumable).
step() {
    local name="$1" min_profile="$2" targets="$3"; shift 3
    if ! _profile_includes "$min_profile"; then
        echo "· [$name] skipped (profile ${PROFILE:-?} < $min_profile)"
        return 0
    fi
    if ! _target_matches "$targets"; then
        echo "· [$name] skipped (target ${TARGET:-?} not in $targets)"
        return 0
    fi
    run_step "$name" "$@"
}

# step_always <name> <min_profile> <targets> <cmd> [args...]
# Like step(), but ALWAYS runs — never recorded in the done-file. Use for work
# that must reconcile on every run (e.g. package installs, so re-running setup
# picks up newly added packages without needing SETUP_FORCE). The command MUST
# be idempotent. Failures are tracked but don't abort the run.
step_always() {
    local name="$1" min_profile="$2" targets="$3"; shift 3
    if ! _profile_includes "$min_profile"; then
        echo "· [$name] skipped (profile ${PROFILE:-?} < $min_profile)"
        return 0
    fi
    if ! _target_matches "$targets"; then
        echo "· [$name] skipped (target ${TARGET:-?} not in $targets)"
        return 0
    fi
    echo "▶ [$name] (always) ..."
    if "$@"; then
        return 0
    fi
    track_failure "$name" "step '$name' failed"
    return 1
}

# Install a package with error tracking (generic wrapper)
install_package() {
    local pkg="$1"
    local install_cmd="$2"

    echo "Installing $pkg..."
    if ! eval "$install_cmd" 2>&1; then
        track_failure "package" "Failed to install $pkg"
        return 1
    fi
    return 0
}

# --- App / setup-repo installers -------------------------------------------
# Some setup repos ship their own install.sh that provisions their tools + config
# (bn does). Those installers drop binaries + symlinks into a bin dir; point them
# at an UNMANAGED dir that's already on PATH so they never overwrite stow-tracked
# files in ~/.bin (itself a symlink into this repo). ~/.local/bin is first on PATH
# (.zshenv/.zshrc).
APP_BIN_DIR="${APP_BIN_DIR:-$HOME/.local/bin}"

# run_app_installer <installer> [args...] — run an app's own install.sh with its
# binaries directed at $APP_BIN_DIR. The app-specific target env (e.g. BN_BIN_DIR)
# is the caller's job; this guarantees the dir exists and runs the script.
run_app_installer() {
    local installer="$1"; shift
    [[ -f "$installer" ]] || { echo "run_app_installer: not found: $installer" >&2; return 1; }
    mkdir -p "$APP_BIN_DIR"
    bash "$installer" "$@"
}

# setup_repo <git-url> [install-args...] — bootstrap an external "setup repo" that
# owns its own install.sh. Instead of vendoring such a repo as a submodule, we clone
# it into the standard worktree layout (~/projects/worktree/<name>/main, the same one
# clone_repos keeps updated) and run its installer. Add a new one by calling this from
# a step in setup.sh. Idempotent: re-clones only when the worktree is missing, and the
# installer itself is expected to be re-runnable.
setup_repo() {
    local url="$1"; shift
    local name="${${url##*/}%.git}"
    local wt_main="$HOME/projects/worktree/$name/main"

    if [[ ! -d "$wt_main" ]]; then
        echo "[$name] cloning setup repo ($url)…"
        if ! "$_COMMON_DIR/../wt" clone "$url"; then
            track_failure "$name" "setup-repo clone failed: $url"; return 1
        fi
    fi
    if [[ ! -f "$wt_main/install.sh" ]]; then
        track_failure "$name" "no install.sh in $wt_main"; return 1
    fi

    echo "[$name] running install.sh $*…"
    if ! run_app_installer "$wt_main/install.sh" "$@"; then
        track_failure "$name" "install.sh failed"; return 1
    fi
}

# Print all failures at the end
print_failure_summary() {
    if [[ ${#SETUP_FAILURES[@]} -eq 0 ]]; then
        echo ""
        echo "=========================================="
        echo "  Setup completed with no failures!"
        echo "=========================================="
        return 0
    fi

    echo ""
    echo "=========================================="
    echo "  Setup completed with ${#SETUP_FAILURES[@]} failure(s):"
    echo "=========================================="
    for failure in "${SETUP_FAILURES[@]}"; do
        echo "  - $failure"
    done
    echo "=========================================="
    echo ""
    echo "You may need to manually fix these issues."
    return 1
}

# Define common software based on environment
# Note: zoxide is NOT in Ubuntu apt repos, so it's installed separately via install_zoxide
if [ "$CODESPACES" = "true" ]; then
    common_software=(
        git stow ripgrep tmux zsh unzip tree jq
    )
else
    common_software=(
        git stow make cmake ripgrep tmux zsh unzip tree jq
    )
fi

detect_distro() {
    if [ "$CODESPACES" = "true" ]; then
        echo "codespace"
    elif [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ]; then
        echo "termux"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ "$(uname)" = "Darwin" ]; then
        echo "darwin"
    else
        echo "Unknown"
    fi
}

# Repos that get regular (non-bare) clones at ~/projects/reponame.
# Single source of truth, shared with .bin/wt (see regular-repos.zsh).
if [[ -f "$_COMMON_DIR/regular-repos.zsh" ]]; then
    source "$_COMMON_DIR/regular-repos.zsh"
else
    REGULAR_CLONE_REPOS=(personal-notes eduuh notes)  # nvim, dotfiles, bn are bare+worktree (see regular-repos.zsh)
fi

# Repos that should live on the Windows filesystem when on WSL
# (cloned to $WINDOWS_PROJECTS_DIR/<name>, symlinked at ~/projects/<name>)
WINDOWS_CLONE_REPOS=(personal-notes notes)

_is_regular_repo() {
    local name="$1"
    for r in "${REGULAR_CLONE_REPOS[@]}"; do
        [[ "$name" == "$r" ]] && return 0
    done
    return 1
}

_is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

# Resolve the Windows-side `projects` directory under the current Windows user's
# profile (e.g. /mnt/c/Users/<user>/projects). Computed lazily so non-WSL hosts
# don't pay the cmd.exe round-trip.
_windows_projects_dir() {
    if [ -z "$WINDOWS_PROJECTS_DIR" ]; then
        _is_wsl || return 1
        local userprofile
        userprofile=$(/mnt/c/Windows/System32/cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r\n')
        [ -z "$userprofile" ] && return 1
        WINDOWS_PROJECTS_DIR="$(wslpath "$userprofile" 2>/dev/null)/projects"
    fi
    echo "$WINDOWS_PROJECTS_DIR"
}

_is_windows_repo() {
    local name="$1"
    _is_wsl || return 1
    for r in "${WINDOWS_CLONE_REPOS[@]}"; do
        [[ "$name" == "$r" ]] && return 0
    done
    return 1
}

# Resolve the on-disk path a regular clone should live at, honoring WSL→Windows rules
_regular_clone_target() {
    local name="$1"
    if _is_windows_repo "$name"; then
        echo "$(_windows_projects_dir)/$name"
    else
        echo "$HOME/projects/$name"
    fi
}

# Run a repo's own ./install.sh if it has one — the generic hook that lets any
# cloned repo (bn, nvim, or a future addition) bootstrap its own tools/build step
# without dotfiles needing repo-specific logic. Idempotent by convention: every
# install.sh here is written to be safe to re-run (incremental cargo builds,
# skip-if-present checks, etc.), so this always runs after a clone/update rather
# than trying to detect "already installed".
_run_repo_install_script() {
    local repo_path="$1" repo_name="$2"
    [ -x "$repo_path/install.sh" ] || return 0
    echo "[$repo_name] Running install.sh..."
    ( cd "$repo_path" && ./install.sh ) || track_failure "$repo_name" "install.sh failed"
}

_clone_single_repo() {
    local REPO="$1"
    local REPO_NAME=$(basename "$REPO" .git)

    if _is_regular_repo "$REPO_NAME"; then
        local CLONE_DIR
        CLONE_DIR=$(_regular_clone_target "$REPO_NAME")
        local SYMLINK_DIR=~/projects/"$REPO_NAME"

        if [ -d "$CLONE_DIR" ] && [ ! -L "$CLONE_DIR" ]; then
            if [ -d "$CLONE_DIR/.git" ]; then
                cd "$CLONE_DIR"
                if ! git diff --quiet || ! git diff --cached --quiet; then
                    echo "[$REPO_NAME] Skipping: unsaved changes."
                else
                    echo "[$REPO_NAME] Updating..."
                    git pull origin "$(git symbolic-ref --short HEAD)" || echo "[$REPO_NAME] Failed to pull."
                    git submodule update --init --recursive || echo "[$REPO_NAME] Failed to update submodules."
                fi
                cd ~
            else
                echo "[$REPO_NAME] Directory exists but is not a git repo. Skipping."
            fi
        else
            if _is_windows_repo "$REPO_NAME"; then
                local win_dir
                win_dir=$(_windows_projects_dir) || { echo "[$REPO_NAME] Could not resolve Windows projects dir."; return 1; }
                mkdir -p "$win_dir" || { echo "[$REPO_NAME] Failed to create $win_dir."; return 1; }
            fi
            echo "[$REPO_NAME] Cloning (regular) → $CLONE_DIR..."
            git clone --recurse-submodules "$REPO" "$CLONE_DIR" || { echo "[$REPO_NAME] Failed to clone."; return 1; }
            # Disable filemode tracking on /mnt/c (NTFS) to avoid spurious 'mode changed' diffs
            if _is_windows_repo "$REPO_NAME"; then
                git -C "$CLONE_DIR" config core.filemode false
            fi
        fi

        # Symlink ~/projects/<name> → $CLONE_DIR if cloned to a non-default location
        if [ "$CLONE_DIR" != "$SYMLINK_DIR" ] && [ ! -e "$SYMLINK_DIR" ]; then
            ln -s "$CLONE_DIR" "$SYMLINK_DIR" && echo "[$REPO_NAME] Symlinked $SYMLINK_DIR → $CLONE_DIR"
        fi
        _run_repo_install_script "$CLONE_DIR" "$REPO_NAME"
    else
        local BARE_PATH=~/projects/bare/"${REPO_NAME}.git"
        local WT_BASE=~/projects/worktree/"$REPO_NAME"
        local ACTIVE_WORKTREE=""

        if [ -d "$BARE_PATH" ]; then
            echo "[$REPO_NAME] Updating (bare)..."
            cd "$BARE_PATH" || return 1
            git fetch origin
            local DEFAULT_BRANCH=$(git symbolic-ref --short HEAD)
            local CURRENT_WORKTREE="$WT_BASE/$DEFAULT_BRANCH"

            if [ -d "$CURRENT_WORKTREE" ]; then
                cd "$CURRENT_WORKTREE"
                git pull origin "$DEFAULT_BRANCH" || echo "[$REPO_NAME] Failed to pull."
                ACTIVE_WORKTREE="$CURRENT_WORKTREE"
            fi
            cd ~
        else
            # Fresh bare clone — delegate to the worktree manager so there's one
            # implementation of "bare clone + default-branch worktree". wt uses
            # the same regular-repos.zsh classification, so it agrees this is bare.
            echo "[$REPO_NAME] Cloning (bare) via wt..."
            "$_COMMON_DIR/../wt" clone "$REPO" || track_failure "$REPO_NAME" "wt clone failed for $REPO"
            # wt clone always checks out the default branch into its own dir under
            # $WT_BASE; there's exactly one at this point, so just glob for it.
            ACTIVE_WORKTREE=$(find "$WT_BASE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n1)
        fi

        # nvim is a bare+worktree repo: point ~/.config/nvim at its main worktree
        # *before* running its install.sh, since some ecosystem installers assume
        # the config dir is already in place.
        if [ -n "$ACTIVE_WORKTREE" ]; then
            [[ "$REPO_NAME" == "nvim" ]] && _setup_nvim_config
            _run_repo_install_script "$ACTIVE_WORKTREE" "$REPO_NAME"
        fi
    fi
}

# Link ~/.config/nvim → the nvim main worktree. Safe to call repeatedly; no-ops if
# the worktree isn't present yet. Ecosystem deps (tree-sitter, vectorcode, mcp-hub)
# are installed by nvim's own install.sh, run generically by _run_repo_install_script.
_setup_nvim_config() {
    local wt_main=~/projects/worktree/nvim/main
    if [ ! -d "$wt_main" ]; then
        echo "[nvim] main worktree not found at $wt_main — skipping config link."
        return 0
    fi
    mkdir -p ~/.config
    ln -sfn "$wt_main" ~/.config/nvim
    echo "[nvim] Linked ~/.config/nvim → $wt_main"
}

# Provision one branch-notes-style repo on Windows + symlink under ~/projects/.
# Used for both the personal `branch-notes` repo and the `branch-notes-work` repo
# for work-classified projects (allowlist in ~/.config/bn/work-repos).
#
# Usage: _setup_one_branch_notes_repo <name> [remote_url]
# If a remote URL is provided and the target has no .git yet, the repo is
# cloned from it. Otherwise the target is initialized as an empty repo.
_setup_one_branch_notes_repo() {
    local name="$1"
    local remote="$2"
    local win_dir target link
    win_dir=$(_windows_projects_dir) || { track_failure "$name" "Could not resolve Windows projects dir"; return 1; }
    target="$win_dir/$name"
    link="$HOME/projects/$name"

    mkdir -p "$win_dir" || { track_failure "$name" "Failed to create $win_dir"; return 1; }

    if [ ! -d "$target/.git" ]; then
        if [ -n "$remote" ]; then
            echo "[$name] Cloning from $remote → $target..."
            git clone "$remote" "$target" || {
                track_failure "$name" "Failed to clone $remote"
                return 1
            }
            git -C "$target" config core.filemode false
        else
            echo "[$name] Initializing repo at $target..."
            mkdir -p "$target"
            (cd "$target" && git init -b main >/dev/null && git config core.filemode false) || {
                track_failure "$name" "Failed to git init $target"
                return 1
            }
        fi
    fi

    if [ -L "$link" ]; then
        return 0
    fi
    if [ -e "$link" ]; then
        track_failure "$name" "$link exists and is not a symlink — refusing to overwrite"
        return 1
    fi
    ln -s "$target" "$link" && echo "[$name] Symlinked $link → $target"
}

# Provision the personal branch-notes repo (work notes are cloned from the
# `notes` remote by clone-work.sh). bn picks the right one per repo via
# $HOME/.config/bn/work-repos (allowlist, gitignored).
#
# WSL keeps the data on the Windows side (symlinked into ~/projects); native
# Linux/macOS clone it straight into ~/projects/branch-notes.
setup_branch_notes_symlink() {
    if _is_wsl; then
        _setup_one_branch_notes_repo "branch-notes" "git@github.com:eduuh/branch-notes.git"
    else
        _setup_branch_notes_native "branch-notes" "git@github.com:eduuh/branch-notes.git"
    fi
}

# Native (non-WSL) branch-notes provisioning: clone the repo into ~/projects/<name>.
# bn may have already created that dir (it writes per-host note folders there before
# this runs); if so, adopt it in place — git init + remote + fetch — so the local
# notes become tracked/pushable rather than failing on a non-empty clone target.
_setup_branch_notes_native() {
    local name="$1" remote="$2"
    local target="$HOME/projects/$name"

    if [ -d "$target/.git" ]; then
        echo "[$name] Already a git repo at $target."
        return 0
    fi

    mkdir -p "$HOME/projects"

    if [ ! -e "$target" ]; then
        echo "[$name] Cloning from $remote → $target..."
        git clone "$remote" "$target" || { track_failure "$name" "Failed to clone $remote"; return 1; }
        git -C "$target" config core.filemode false
        return 0
    fi

    # Target exists but isn't a git repo (e.g. bn created it). Adopt it: init,
    # wire the remote, and fetch/checkout the default branch without discarding
    # the local files already there.
    echo "[$name] $target exists but is not a git repo — adopting it (git init + remote)..."
    git -C "$target" init -b main >/dev/null || { track_failure "$name" "Failed to git init $target"; return 1; }
    git -C "$target" config core.filemode false
    if ! git -C "$target" remote get-url origin >/dev/null 2>&1; then
        git -C "$target" remote add origin "$remote"
    fi
    if ! git -C "$target" fetch origin >/dev/null 2>&1; then
        track_failure "$name" "Failed to fetch $remote into adopted $target"
        return 1
    fi
    local def
    def=$(git -C "$target" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
    def="${def:-main}"
    # Point local branch at origin's tip; local note files stay as working-tree
    # changes to review/commit, nothing is overwritten or deleted.
    git -C "$target" checkout -B "$def" --track "origin/$def" 2>/dev/null \
        || git -C "$target" branch --set-upstream-to="origin/$def" "$def" 2>/dev/null || true
    echo "[$name] Adopted $target (remote origin → $remote, branch $def)."
}

clone_repos() {
    cd ~
    mkdir -p ~/projects ~/projects/bare ~/projects/worktree

    # Detect if running on WSL
    local is_wsl=false
    if grep -qi microsoft /proc/version 2>/dev/null; then
        is_wsl=true
    fi

    local REPOSITORIES=()
    if [ "$CODESPACES" = "true" ]; then
        REPOSITORIES=(
            "https://github.com/eduuh/dotfiles.git"
            "git@github.com:eduuh-private/personal-notes.git"
        )
    else
        REPOSITORIES=(
            "git@github.com:eduuh/dotfiles.git"
            "git@github.com:eduuh/nvim.git"
            "git@github.com:eduuh-private/personal-notes.git"
            "git@github.com:eduuh/eduuh.git"
            "git@github.com:eduuh/bn.git"
            "git@github.com:eduuh/atlas.git"
        )

        if [ "$is_wsl" = true ] && [ "$(hostname)" = "edwin" ]; then
            REPOSITORIES+=(
                "git@github.com:eduuh/kube-homelab.git"
                "git@github.com:eduuh/bits-and-atoms.git"
            )
        elif [ "$is_wsl" = false ]; then
            REPOSITORIES+=(
                "git@github.com:eduuh/kube-homelab.git"
                "git@github.com:eduuh/blog-2026.git"
                "git@github.com:eduuh/growatt_exporter.git"
                "git@github.com:eduuh-private/byte_s.git"
                "git@github.com:eduuh-private/bash.git"
                "git@github.com:eduuh-private/eduuh-blog-template.git"
                "git@github.com:eduuh-private/life.git"
                "git@github.com:eduuh/bits-and-atoms.git"
            )
        fi
    fi

    echo "Cloning ${#REPOSITORIES[@]} repositories in parallel..."
    for REPO in "${REPOSITORIES[@]}"; do
        _clone_single_repo "$REPO" &
    done
    wait
    echo "All repository clones finished."

    setup_branch_notes_symlink
    _run_work_setup_from_personal_notes
    _run_personal_setup_from_personal_notes
}

# After personal repos are cloned, source a personal-only-repo setup script from
# personal-notes if it exists. Mirrors _run_work_setup_from_personal_notes but for
# repos that must NEVER land on a work machine (e.g. mt5-data-api, trading
# journals): the script defines its own repo list, calls _clone_single_repo /
# bn wt clone for each, so those repo names+URLs stay private instead of in this
# public dotfiles repo. No-op if personal-notes isn't cloned or the script is absent.
_run_personal_setup_from_personal_notes() {
    local personal_script="${PERSONAL_SETUP_SCRIPT:-$HOME/projects/personal-notes/scripts/setup-personal-repos.sh}"
    if [[ ! -f "$personal_script" ]]; then
        return 0
    fi
    echo "Sourcing personal setup script: $personal_script"
    source "$personal_script"
    echo "Personal repo setup finished."
}

# After personal repos are cloned, source a work-repo setup script from
# personal-notes if it exists. The script defines a WORK_REPOS array, calls
# _clone_single_repo, and/or calls _setup_one_branch_notes_repo with a remote
# URL — so the list of work repos and their URLs stay in the private
# personal-notes repo instead of this public dotfiles repo.
_run_work_setup_from_personal_notes() {
    local work_script="${WORK_SETUP_SCRIPT:-$HOME/projects/personal-notes/scripts/setup-work-repos.sh}"
    if [[ ! -f "$work_script" ]]; then
        return 0
    fi
    echo "Sourcing work setup script: $work_script"
    source "$work_script"
    echo "Work repo setup finished."
}

# Work-machine tool installs (agency, etc.). Runs only via `setup.sh --work`.
# Delegates to a script in the private personal-notes repo so internal MS
# endpoints stay out of public dotfiles. No-op if the script is absent.
install_work_tools() {
    local work_tools="${WORK_TOOLS_SCRIPT:-$HOME/projects/personal-notes/scripts/setup-work-tools.sh}"
    if [[ ! -f "$work_tools" ]]; then
        echo "· no work-tools script at $work_tools — skipping"
        return 0
    fi
    echo "Sourcing work tools script: $work_tools"
    source "$work_tools"
}

ensure_tmux_version() {
    # 3.5 is the floor: popup borders/titles (3.4) and robust OSC52 set-clipboard
    # (3.3) are relied on by tmux.conf. 3.2a (Ubuntu's apt candidate) is too old,
    # so this triggers the from-source build below.
    local min_version="3.5"

    # macOS via Homebrew always has recent tmux, skip
    if [[ "$(uname)" == "Darwin" ]]; then
        return 0
    fi

    # Check current tmux version
    if command -v tmux &> /dev/null; then
        local current_version
        current_version=$(tmux -V | sed -n 's/^tmux \([0-9.]*\).*/\1/p')

        if [[ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" == "$min_version" ]]; then
            echo "tmux $current_version is installed (>= $min_version required). OK."
            return 0
        fi
        echo "tmux $current_version is too old (need >= $min_version). Installing from source..."
    else
        echo "tmux not found. Installing from source..."
    fi

    # Install build dependencies based on distro
    echo "Installing tmux build dependencies..."
    if command -v pacman &> /dev/null; then
        sudo pacman -S --needed --noconfirm libevent ncurses base-devel bison pkg-config || {
            track_failure "tmux" "Failed to install tmux build dependencies"
            return 1
        }
    elif command -v rpm-ostree &> /dev/null || command -v dnf &> /dev/null; then
        # Fedora / rpm-ostree: layer on atomic, dnf on traditional.
        local _tmux_deps=(libevent-devel ncurses-devel gcc make bison pkgconf-pkg-config)
        if [[ -f /run/ostree-booted ]]; then
            sudo rpm-ostree install --idempotent --allow-inactive --apply-live -y "${_tmux_deps[@]}" || {
                track_failure "tmux" "Failed to install tmux build dependencies"
                return 1
            }
        else
            sudo dnf install -y "${_tmux_deps[@]}" || {
                track_failure "tmux" "Failed to install tmux build dependencies"
                return 1
            }
        fi
    else
        sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config || {
            track_failure "tmux" "Failed to install tmux build dependencies"
            return 1
        }
    fi

    # Build tmux from source
    local tmux_version="${TMUX_VERSION:-3.5a}"
    local build_dir="/tmp/tmux-build"

    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir" || return 1

    echo "Downloading tmux $tmux_version..."
    if ! curl -sLO "https://github.com/tmux/tmux/releases/download/${tmux_version}/tmux-${tmux_version}.tar.gz"; then
        track_failure "tmux" "Failed to download tmux source"
        cd ~ || return 1
        return 1
    fi

    tar -xzf "tmux-${tmux_version}.tar.gz"
    cd "tmux-${tmux_version}" || return 1

    echo "Building tmux..."
    if ! ./configure && make; then
        track_failure "tmux" "Failed to build tmux"
        cd ~ || return 1
        return 1
    fi

    echo "Installing tmux..."
    if ! sudo make install; then
        track_failure "tmux" "Failed to install tmux"
        cd ~ || return 1
        return 1
    fi

    cd ~ || return 1
    rm -rf "$build_dir"

    echo "tmux $(tmux -V) installed successfully."
}

# TPM removed: bn vendors its tmux plugins (tmux-resurrect + tmux-continuum) in-repo and
# sources them directly from its tmux.conf, so there is no plugin manager to bootstrap.
install_tmux_plugins() {
    echo "tmux plugins are bundled with bn — nothing to install."
}

install_neovim() {
    echo "Installing Neovim from GitHub releases..."
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"

    local arch=$(uname -m)
    local tarball="nvim-linux-${arch}.tar.gz"
    local url
    if [[ -n "${NVIM_VERSION:-}" ]]; then
        url="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${tarball}"
    else
        url="https://github.com/neovim/neovim/releases/latest/download/${tarball}"
    fi

    if ! curl -sL "$url" -o "/tmp/${tarball}"; then
        track_failure "neovim" "Failed to download Neovim"
        return 1
    fi

    tar -xzf "/tmp/${tarball}" -C /tmp
    # Install the FULL tree (binary + lib/parsers + share/nvim/runtime) under
    # ~/.local so nvim finds its matching runtime relative to the binary. Copying
    # only bin/nvim leaves it to fall back to a mismatched system runtime, which
    # breaks real configs (e.g. "module 'vim.uri' not found").
    local src="/tmp/nvim-linux-${arch}"
    mkdir -p "$install_dir" "$HOME/.local/lib" "$HOME/.local/share"
    cp -af "$src/bin/nvim" "$install_dir/nvim"
    cp -af "$src/lib/."   "$HOME/.local/lib/"
    cp -af "$src/share/." "$HOME/.local/share/"
    chmod +x "$install_dir/nvim"
    rm -rf "/tmp/${tarball}" "$src"

    echo "Neovim $("$install_dir/nvim" --version | head -1) installed to $install_dir"
}

install_fzf() {
    echo "Installing fzf from GitHub releases..."
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"

    local version="${FZF_VERSION:-}"
    if [[ -z "$version" ]]; then
        version=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    fi
    if [[ -z "$version" ]]; then
        track_failure "fzf" "Failed to fetch fzf version"
        return 1
    fi

    local url="https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-linux_amd64.tar.gz"

    if ! curl -sL "$url" -o /tmp/fzf.tar.gz; then
        track_failure "fzf" "Failed to download fzf"
        return 1
    fi

    tar -xzf /tmp/fzf.tar.gz -C "$install_dir" fzf
    chmod +x "$install_dir/fzf"
    rm -f /tmp/fzf.tar.gz

    echo "fzf $("$install_dir/fzf" --version) installed to $install_dir"
}

install_lazygit() {
    if command -v lazygit &> /dev/null; then
        echo "LazyGit is already installed."
        return 0
    fi

    # macOS: installed via Brewfile, only need the Linux path
    echo "Installing LazyGit..."
    if ! command -v curl &> /dev/null; then
        echo "Installing curl..."
        sudo apt-get install -y curl || sudo pacman -S --noconfirm curl || {
            track_failure "lazygit" "Failed to install curl (required for lazygit)"
            return 0
        }
    fi

    local lazygit_version="${LAZYGIT_VERSION:-}"
    if [[ -z "$lazygit_version" ]]; then
        lazygit_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    fi
    if [[ -z "$lazygit_version" ]]; then
        track_failure "lazygit" "Failed to fetch lazygit version"
        return 0
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' RETURN

    if curl -Lo "$tmpdir/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_x86_64.tar.gz" && \
       tar xf "$tmpdir/lazygit.tar.gz" -C "$tmpdir" lazygit && \
       sudo install -D "$tmpdir/lazygit" -t /usr/local/bin/; then
        echo "LazyGit $lazygit_version installed."
    else
        track_failure "lazygit" "Failed to download/install lazygit"
    fi
}

install_zoxide() {
    if command -v zoxide &> /dev/null; then
        echo "zoxide is already installed."
        return 0
    fi

    # macOS: installed via Brewfile, only need the Linux path
    echo "Installing zoxide..."
    if ! curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        track_failure "zoxide" "Failed to install zoxide via install script"
    else
        if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
        fi
    fi
}

install_starship() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping Starship installation."
        return 0
    fi

    if command -v starship &> /dev/null; then
        echo "Starship is already installed."
        return 0
    fi

    # macOS: installed via Brewfile, only need the Linux path
    echo "Installing Starship..."
    if ! curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        track_failure "starship" "Failed to install starship"
    fi
}

install_claude_code() {
    if command -v claude &> /dev/null; then
        echo "Claude Code is already installed."
        return 0
    fi

    echo "Installing Claude Code..."
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        track_failure "claude-code" "Failed to install Claude Code"
    fi
}

install_rust() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping Rust installation."
        return 0
    fi

    if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
        echo "Rust is already installed."
        return 0
    fi

    echo "Installing Rust (toolchain ${RUST_TOOLCHAIN:-stable})..."
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "${RUST_TOOLCHAIN:-stable}"; then
        # Source the cargo environment for the current session
        [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    else
        track_failure "rust" "Failed to install Rust"
    fi
}

setup_bn() {
    # bn ships the branch-notes CLI + bn-mcp server and (full install) owns the tmux
    # config: ~/.tmux.conf → workflow/tmux.conf plus ~/.config/bn/{repo,bn}. It used to
    # be a submodule built by dotfiles; now it's an external setup repo — clone it and
    # run its own install.sh (see setup_repo). install.sh registers bn-mcp for Claude
    # Code + Copilot and pulls the prebuilt release via authenticated `gh`, building from
    # source (rust step runs first) only as a fallback. Cut a new bn release (tag vX.Y.Z)
    # to advance the deployed binary. BN_BIN_DIR keeps the install off ~/.bin (stow-
    # managed) → ~/.local/bin, first on PATH. Codespaces get --core (no tmux layer).
    export BN_BIN_DIR="$APP_BIN_DIR"
    if [[ "$CODESPACES" == "true" ]]; then
        setup_repo "https://github.com/eduuh/bn.git" --core
    else
        setup_repo "git@github.com:eduuh/bn.git"
    fi
}

install_playwright() {
    if command -v playwright &> /dev/null; then
        echo "Playwright is already installed."
        return 0
    fi

    echo "Installing Playwright..."
    if ! npm install -g playwright; then
        track_failure "playwright" "Failed to install Playwright"
    fi
}

install_pnpm() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping PNPM installation."
        return 0
    fi

    if command -v pnpm &> /dev/null; then
        echo "PNPM is already installed."
        return 0
    fi

    echo "Installing PNPM..."
    # Override any inherited PNPM_HOME (e.g. a macOS path leaking into a Linux
    # shell from a shared .zshrc) so the installer writes to the correct
    # per-OS location.
    case "$(uname -s)" in
        Darwin) export PNPM_HOME="$HOME/Library/pnpm" ;;
        *)      export PNPM_HOME="$HOME/.local/share/pnpm" ;;
    esac
    # The get.pnpm.io installer honours $PNPM_VERSION; export it so the piped sh sees it.
    [[ -n "${PNPM_VERSION:-}" ]] && export PNPM_VERSION
    if curl -fsSL https://get.pnpm.io/install.sh | sh -s -- -y; then
        case ":$PATH:" in
            *":$PNPM_HOME:"*) ;;
            *) export PATH="$PNPM_HOME:$PATH" ;;
        esac
    else
        track_failure "pnpm" "Failed to install PNPM"
    fi
}

install_talosctl() {
    # Skip on WSL - talosctl should be installed on Windows host
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "Skipping talosctl on WSL (install on Windows host instead)."
        return 0
    fi

    # Skip on Fedora — not part of the Fedora toolset, and the upstream installer
    # (talos.dev/install) lacks a working checksum path there.
    if [[ "$(detect_distro)" == "fedora" ]]; then
        echo "Skipping talosctl on Fedora."
        return 0
    fi

    if command -v talosctl &> /dev/null; then
        echo "talosctl is already installed."
        return 0
    fi

    echo "Installing talosctl..."
    if ! curl -sL https://talos.dev/install | sh; then
        track_failure "talosctl" "Failed to install talosctl"
    fi
}

setup_python() {
    if [[ $CODESPACES == "true" ]]; then
        echo "In a GitHub Codespace environment, skipping Python setup."
        return 0
    fi

    if [[ "${SETUP_PYTHON:-0}" != "1" ]]; then
        echo "Skipping Python setup (set SETUP_PYTHON=1 to enable)."
        return 0
    fi

    echo "Setting up Python environment..."
    local venv_dir="$HOME/.local/state/python3"
    if [ -d "$venv_dir" ] && ! "$venv_dir/bin/python3" -m pip --version &> /dev/null; then
        echo "Existing venv is missing pip — recreating."
        rm -rf "$venv_dir"
    fi
    if [ -d "$venv_dir" ]; then
        echo "Python virtual environment already exists."
        source "$venv_dir/bin/activate"
    else
        echo "Creating Python virtual environment..."
        if ! python3 -m venv "$venv_dir"; then
            track_failure "python" "Failed to create Python virtual environment"
            return 0
        fi
        source "$venv_dir/bin/activate"
    fi

    if ! pip install --upgrade pip pynvim requests; then
        track_failure "python" "Failed to install Python packages (pip, pynvim, requests)"
    fi
}

install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        echo "NVM is already installed."
        return 0
    fi

    echo "Installing NVM..."
    if ! curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION:-v0.40.1}/install.sh" | bash -s -- --no-use --silent; then
        track_failure "nvm" "Failed to install NVM"
        return 0
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

    if ! nvm install --lts; then
        track_failure "nvm" "Failed to install Node.js LTS via NVM"
    fi
}

setup_symlinks() {
    # dotfiles is a bare+worktree repo: stow always from the main worktree so the
    # $HOME symlinks stay stable no matter which worktree you're editing in. Fall
    # back to a flat ~/projects/dotfiles for entrypoints that still clone flat.
    local dotfiles_dir=~/projects/worktree/dotfiles/main
    [ -d "$dotfiles_dir" ] || dotfiles_dir=~/projects/dotfiles

    echo "Stowing dotfiles from $dotfiles_dir..."
    cd "$dotfiles_dir"
    if ! stow --adopt -t "$HOME" .; then
        track_failure "symlinks" "Failed to create symlinks with stow"
    fi
}

setup_personal_notes_stow() {
    local stow_dir=~/projects/personal-notes/stow

    if [ ! -d "$stow_dir" ]; then
        echo "personal-notes stow directory not found at $stow_dir — skipping."
        echo "Run setup-projects.sh first to clone personal-notes."
        return 0
    fi

    echo "Stowing personal-notes from $stow_dir..."
    cd "$stow_dir"
    if ! stow -vt "$HOME" home; then
        track_failure "personal-notes-stow" "Failed to stow personal-notes"
    fi
}

setup_git_hooks() {
    echo "Setting up git hooks for all projects..."
    local hook_src_dir="$HOME/projects/worktree/dotfiles/main/.bin/git-hooks"
    [ -d "$hook_src_dir" ] || hook_src_dir="$HOME/projects/dotfiles/.bin/git-hooks"

    if [ ! -d "$hook_src_dir" ]; then
        track_failure "git-hooks" "Hook source dir not found at $hook_src_dir"
        return 0
    fi

    # Symlink every hook in .bin/git-hooks/ into a repo's hooks dir (pre-push,
    # pre-commit, …). Adding a new hook there needs no change here.
    _link_hooks() {
        local dest="$1" hook
        mkdir -p "$dest"
        for hook in "$hook_src_dir"/*(N.); do
            ln -sf "$hook" "$dest/${hook:t}" || track_failure "git-hooks" "Failed to link ${hook:t} into $dest"
        done
    }

    # Bare repos — hooks are shared across all their worktrees.
    for bare in ~/projects/bare/*.git(N/); do
        echo "Installing hooks in $(basename "$bare")..."
        _link_hooks "$bare/hooks"
    done

    # Regular clones (personal-notes). nvim and dotfiles are bare+worktree — their
    # hooks are installed by the ~/projects/bare/*.git loop above.
    for project in personal-notes; do
        local git_dir=~/projects/"$project"/.git
        if [ -d "$git_dir" ]; then
            echo "Installing hooks in $project..."
            _link_hooks "$git_dir/hooks"
        fi
    done
}

change_shell_to_zsh() {
    if [[ "$CODESPACES" == "true" ]]; then
        echo "Skipping shell change in Codespaces environment."
        return 0
    fi

    local zsh_path
    zsh_path=$(command -v zsh)

    if [[ "$SHELL" != "$zsh_path" ]]; then
        echo "Changing default shell to zsh ($zsh_path)..."

        # Handle platform-specific shell change commands
        case "$(detect_distro)" in
            darwin)
                # macOS doesn't need sudo for chsh
                if ! chsh -s "$zsh_path"; then
                    track_failure "shell" "Failed to change shell to zsh"
                fi
                ;;
            termux)
                # Termux has no sudo; chsh works directly
                if ! chsh -s "$zsh_path"; then
                    track_failure "shell" "Failed to change shell to zsh"
                fi
                ;;
            *)
                # Linux distributions typically need sudo
                if ! sudo chsh -s "$zsh_path" "$USER"; then
                    track_failure "shell" "Failed to change shell to zsh"
                fi
                ;;
        esac
    else
        echo "Shell is already set to zsh."
    fi
}
