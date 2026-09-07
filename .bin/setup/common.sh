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
: "${SETUP_FAILURES_FILE:=}"
: "${SETUP_WORK:=false}"
: "${SETUP_PERSONAL:=false}"

# Failure tracking - collect errors instead of exiting
typeset -ga SETUP_FAILURES=()

track_failure() {
    local component="$1"
    local message="$2"
    SETUP_FAILURES+=("[$component] $message")
    # A background job gets its own COPY of the array, so failures inside the
    # parallel clones never reached the parent and setup happily reported
    # "no failures". When a collector file is set, append there too; whoever set
    # it drains the file back into the array after `wait`. Short O_APPEND writes
    # from concurrent jobs don't interleave.
    if [[ -n "${SETUP_FAILURES_FILE:-}" ]]; then
        print -r -- "[$component] $message" >> "$SETUP_FAILURES_FILE"
    fi
    echo "WARNING: $message (continuing...)"
}

# Drain a collector file written by background jobs into SETUP_FAILURES.
_drain_failures() {
    local file="$1" line
    [[ -s "$file" ]] || return 0
    while IFS= read -r line; do
        [[ -n "$line" ]] && SETUP_FAILURES+=("$line")
    done < "$file"
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
# (cloned to $WINDOWS_PROJECTS_DIR/<name>, symlinked at ~/projects/<name>).
# win-dot and keyflow are Windows applications — they are built and run from the
# Windows side, so a clone inside the WSL filesystem would be unusable there.
WINDOWS_CLONE_REPOS=(personal-notes notes win-dot keyflow)

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
# Conventional names for a repo's own dependency installer, tried in order. This
# used to look for install.sh ONLY, so nvim — which ships install-deps.sh — was
# cloned without ever installing its dependencies, silently. Nothing failed; the
# hook just no-opped, and the comment in _setup_nvim_config below confidently
# claimed the opposite.
#
# Run non-interactively: clone_repos calls this from a background job with no tty,
# so an installer that needs sudo will fail fast rather than hang waiting for a
# password nobody can type. Re-run it by hand on a fresh machine if that happens.
_REPO_INSTALL_SCRIPTS=(install.sh install-deps.sh)

_run_repo_install_script() {
    local repo_path="$1" repo_name="$2" script
    for script in "${_REPO_INSTALL_SCRIPTS[@]}"; do
        [ -f "$repo_path/$script" ] || continue
        echo "[$repo_name] Running $script..."
        if [ -x "$repo_path/$script" ]; then
            ( cd "$repo_path" && "./$script" ) || track_failure "$repo_name" "$script failed"
        else
            # Tracked without the exec bit (common on the Windows filesystem, where
            # core.filemode is false) — still runnable.
            ( cd "$repo_path" && sh "./$script" ) || track_failure "$repo_name" "$script failed"
        fi
        return 0   # first match wins; a repo has one installer
    done
    return 0
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
                track_failure "$REPO_NAME" "$CLONE_DIR exists but is not a git repo — skipped"
            fi
        else
            if _is_windows_repo "$REPO_NAME"; then
                local win_dir
                win_dir=$(_windows_projects_dir) || { echo "[$REPO_NAME] Could not resolve Windows projects dir."; return 1; }
                mkdir -p "$win_dir" || { echo "[$REPO_NAME] Failed to create $win_dir."; return 1; }
            fi
            echo "[$REPO_NAME] Cloning (regular) → $CLONE_DIR..."
            if ! git clone --recurse-submodules "$REPO" "$CLONE_DIR"; then
                track_failure "$REPO_NAME" "Failed to clone $REPO into $CLONE_DIR"
                return 1
            fi
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
        # *before* running its installer, since some ecosystem installers assume
        # the config dir is already in place.
        if [ -n "$ACTIVE_WORKTREE" ]; then
            [[ "$REPO_NAME" == "nvim" ]] && _setup_nvim_config
            _run_repo_install_script "$ACTIVE_WORKTREE" "$REPO_NAME"
        fi
    fi
}

# Link ~/.config/nvim → the nvim main worktree. Safe to call repeatedly; no-ops if
# the worktree isn't present yet. Ecosystem deps (tree-sitter, vectorcode, mcp-hub)
# are installed by nvim's own install-deps.sh, run generically by
# _run_repo_install_script right after the clone.
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

# Provision a branch-notes repo, picking the right layout for the platform: WSL
# keeps the data on the Windows side (symlinked into ~/projects) so Windows-side
# editors can reach it, native Linux/macOS clones straight into ~/projects/<name>.
#
# The NAME AND REMOTE ARE THE CALLER'S to supply, and both callers are private
# setup scripts in personal-notes: setup-personal-repos.sh provisions the personal
# notes repo under --personal, setup-work-repos.sh the work one under --work. So a
# work machine never clones personal notes and vice versa, and neither private
# repo's name sits in this public repo. bn routes writes to the right one per repo
# via $HOME/.config/bn/work-repos (allowlist, gitignored).
#
# Usage: setup_branch_notes_repo <name> <remote_url>
setup_branch_notes_repo() {
    local name="$1" remote="$2"
    if [[ -z "$name" ]]; then
        track_failure "branch-notes" "setup_branch_notes_repo needs a repo name"
        return 1
    fi
    if _is_wsl; then
        _setup_one_branch_notes_repo "$name" "$remote"
    else
        _setup_branch_notes_native "$name" "$remote"
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

# personal-notes is the private repo the rest of the setup hangs off: the stow
# tree (setup_personal_notes_stow), the work/personal repo setup scripts, the
# work-tools installer, and the tmux planning session all read from it. So it is
# cloned on EVERY setup run rather than only inside clone_repos — that step runs
# detached and is skipped once its `projects` marker is recorded, which would
# leave a machine that missed it once permanently without personal-notes.
#
# HTTPS, not SSH, and authenticated through `gh`: the only SSH key on a work
# machine belongs to the work GitHub account, which cannot see this repo, so an
# SSH clone dies with "Repository not found". gh already holds the eduuh token.
PERSONAL_NOTES_REMOTE="${PERSONAL_NOTES_REMOTE:-https://github.com/eduuh/personal-notes.git}"

# Clone (or update) personal-notes and re-stow it. Idempotent — safe for step_always.
#
# The gh credential helper is forced on via GIT_CONFIG_* rather than relying on
# ~/.gitconfig, so this works before the dotfiles are stowed and can't be hijacked
# by whatever credential manager the host has configured.
ensure_personal_notes() {
    mkdir -p ~/projects

    # A file:// remote (tests) needs no auth; anything on github.com does.
    if [[ "$PERSONAL_NOTES_REMOTE" == https://github.com/* ]]; then
        if ! command -v gh >/dev/null 2>&1; then
            track_failure "personal-notes" "gh not installed — cannot authenticate $PERSONAL_NOTES_REMOTE"
            return 1
        fi
        if ! gh auth status >/dev/null 2>&1; then
            track_failure "personal-notes" "gh is not logged in — run: gh auth login (as eduuh), then re-run setup"
            return 1
        fi
        local -x GIT_CONFIG_COUNT=1
        local -x GIT_CONFIG_KEY_0="credential.https://github.com.helper"
        local -x GIT_CONFIG_VALUE_0="!$(command -v gh) auth git-credential"
        local -x GIT_TERMINAL_PROMPT=0
    fi

    if ! _clone_single_repo "$PERSONAL_NOTES_REMOTE"; then
        track_failure "personal-notes" "Failed to clone/update $PERSONAL_NOTES_REMOTE"
        return 1
    fi
    setup_personal_notes_stow
}

# A clone run has a SHAPE: plain, --personal, --work, or both. Each clones a
# different set, so they cannot share one "projects" marker — a machine set up
# plain would then skip the clone forever and never pick up the repos a flag adds.
_projects_step_name() {
    local name=projects
    [[ "$SETUP_PERSONAL" == "true" ]] && name="$name-personal"
    [[ "$SETUP_WORK" == "true" ]] && name="$name-work"
    echo "$name"
}

# A completed run also satisfies every smaller shape it contains.
_projects_mark_done() {
    _step_mark_done projects
    [[ "$SETUP_PERSONAL" == "true" ]] && _step_mark_done projects-personal
    [[ "$SETUP_WORK" == "true" ]] && _step_mark_done projects-work
    [[ "$SETUP_PERSONAL" == "true" && "$SETUP_WORK" == "true" ]] && _step_mark_done projects-personal-work
    return 0
}

# Clone the long-tail project repos. personal-notes is deliberately NOT in this
# list: ensure_personal_notes clones it up front and synchronously, because the
# work/personal setup scripts below live inside it.
clone_repos() {
    cd ~
    mkdir -p ~/projects ~/projects/bare ~/projects/worktree

    local REPOSITORIES=()
    if [ "$CODESPACES" = "true" ]; then
        REPOSITORIES=(
            "https://github.com/eduuh/dotfiles.git"
        )
    else
        # Toolchain — what every machine needs to be usable, work or personal.
        REPOSITORIES=(
            "git@github.com:eduuh/dotfiles.git"
            "git@github.com:eduuh/nvim.git"
            "git@github.com:eduuh/eduuh.git"
            "git@github.com:eduuh/bn.git"
            "git@github.com:eduuh/atlas.git"
        )

        # Windows-side applications. WSL only — they are meaningless on a native
        # Linux or mac box — but NOT behind --personal: this is the Windows half
        # of the machine's own config, wanted on a work machine too.
        if _is_wsl; then
            REPOSITORIES+=(
                "https://github.com/eduuh/win-dot.git"
                "https://github.com/eduuh/keyflow.git"
            )
        fi

        # Personal PROJECT repos that are themselves public — nothing to hide, so
        # the names stay here. A work machine still shouldn't pull them, so they
        # sit behind --personal like the private ones. Repos that are actually
        # PRIVATE live in personal-notes' scripts/setup-personal-repos.sh instead,
        # so their names and URLs never appear in a public repo.
        if [[ "$SETUP_PERSONAL" == "true" ]]; then
            REPOSITORIES+=(
                "git@github.com:eduuh/bits-and-atoms.git"
                "git@github.com:eduuh/growatt_exporter.git"
            )
        fi
    fi

    # Collect failures from every background job for the WHOLE function, the sourced
    # work/personal hooks included — they run their own parallel `_clone_single_repo`
    # loops, so closing the window right after the loop below lost theirs: a run in
    # which six repos failed to clone reported only the two that happened to fail in
    # this loop, and the summary called the rest a success.
    local failures_file
    failures_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles-clone-failures.XXXXXX")
    SETUP_FAILURES_FILE="$failures_file"

    echo "Cloning ${#REPOSITORIES[@]} repositories in parallel..."
    for REPO in "${REPOSITORIES[@]}"; do
        _clone_single_repo "$REPO" &
    done
    wait
    echo "All repository clones finished."

    # Branch-notes repos are NOT provisioned here. They are private and they are
    # per-side: the private hooks below call setup_branch_notes_repo themselves, so
    # --personal gets the personal notes repo and --work the work one. Doing it
    # unconditionally here meant a work machine tried to clone personal notes on
    # every run — and failed, because a work SSH key cannot read that repo.
    #
    # Work repos are opt-in (--work) and always come AFTER personal-notes, which
    # holds the script that lists them. ensure_personal_notes has already run —
    # synchronously, from setup.sh or from setup-projects.sh — before we get here.
    if [[ "${SETUP_WORK:-false}" == "true" ]]; then
        _run_work_setup_from_personal_notes
    else
        echo "· work repos skipped (no --work)"
    fi
    # Personal repos are opt-in too (--personal), for the same reason as work:
    # a work machine should never pull them, and the list is private.
    if [[ "$SETUP_PERSONAL" == "true" ]]; then
        _run_personal_setup_from_personal_notes
    else
        echo "· personal repos skipped (no --personal)"
    fi

    SETUP_FAILURES_FILE=""
    _drain_failures "$failures_file"
    rm -f "$failures_file"
}

# After personal repos are cloned, source a personal-only-repo setup script from
# personal-notes if it exists. Mirrors _run_work_setup_from_personal_notes but for
# repos that must NEVER land on a work machine: the script defines its own repo
# list and calls _clone_single_repo / bn wt clone for each, so those repo names
# and URLs stay private instead of sitting in this public dotfiles repo. No-op if
# personal-notes isn't cloned or the script is absent.
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

# Work-machine tool installs. Runs only via `setup.sh --work`.
# Delegates to a script in the private personal-notes repo so internal MS
# endpoints stay out of public dotfiles. No-op if the script is absent.
install_work_tools() {
    local work_tools="${WORK_TOOLS_SCRIPT:-$HOME/projects/personal-notes/scripts/setup-work-tools.sh}"
    if [[ ! -f "$work_tools" ]]; then
        # Non-zero on purpose: --work was asked for and could not be honored.
        # Silently returning 0 here would let `step` record work-tools as done and
        # skip it forever, even once personal-notes finally lands.
        track_failure "work-tools" "no work-tools script at $work_tools (is personal-notes cloned?)"
        return 1
    fi
    echo "Sourcing work tools script: $work_tools"
    source "$work_tools"
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

# sccache: compiler cache for Rust. The .zshrc/.bashrc build-cache block wires
# RUSTC_WRAPPER=sccache when the binary exists, so installing it here (prebuilt
# from GitHub → ~/.local/bin) is what actually turns the cache on for a fresh
# machine. Big win on clean/CI-path rebuilds (~8x); cross-worktree hits are
# limited because sccache's Rust key includes dependency paths.
install_sccache() {
    local ver="${SCCACHE_VERSION:-v0.16.0}"
    local install_dir="$APP_BIN_DIR"
    mkdir -p "$install_dir"

    if [[ -x "$install_dir/sccache" ]] && "$install_dir/sccache" --version 2>/dev/null | grep -q "${ver#v}"; then
        echo "sccache ${ver} already installed."
        return 0
    fi

    local os arch triple
    os="$(uname -s)"; arch="$(uname -m)"
    case "$os:$arch" in
        Linux:x86_64)          triple="x86_64-unknown-linux-musl" ;;
        Linux:aarch64|Linux:arm64) triple="aarch64-unknown-linux-musl" ;;
        Darwin:x86_64)         triple="x86_64-apple-darwin" ;;
        Darwin:arm64|Darwin:aarch64) triple="aarch64-apple-darwin" ;;
        *) track_failure "sccache" "Unsupported platform $os/$arch"; return 0 ;;
    esac

    local name="sccache-${ver}-${triple}"
    local url="https://github.com/mozilla/sccache/releases/download/${ver}/${name}.tar.gz"
    local tmpdir; tmpdir="$(mktemp -d)"

    if curl -fsSL "$url" -o "$tmpdir/sccache.tar.gz" && \
       tar -xzf "$tmpdir/sccache.tar.gz" -C "$tmpdir" && \
       install -m755 "$tmpdir/$name/sccache" "$install_dir/sccache"; then
        echo "$("$install_dir/sccache" --version) installed to $install_dir"
    else
        track_failure "sccache" "Failed to download/install sccache"
    fi
    rm -rf "$tmpdir"
}

# mold: fast drop-in linker. The build-cache rc block adds `-fuse-ld=mold` when
# the binary exists. gcc's -fuse-ld=mold needs an `ld.mold` alias on PATH, so we
# install BOTH `mold` and `ld.mold`. Linux-only (macOS has no free mold). After
# installing we functionally probe a trivial link; if it fails on this box we
# remove mold so the rc guard leaves the toolchain's default linker in place.
install_mold() {
    [[ "$(uname -s)" == "Linux" ]] || { echo "mold is Linux-only; skipping."; return 0; }
    local ver="${MOLD_VERSION:-2.41.0}"
    local install_dir="$APP_BIN_DIR"
    mkdir -p "$install_dir"

    if [[ -x "$install_dir/mold" && -x "$install_dir/ld.mold" ]] && \
       "$install_dir/mold" --version 2>/dev/null | grep -q "mold ${ver}"; then
        echo "mold ${ver} already installed."
        return 0
    fi

    local arch march
    arch="$(uname -m)"
    case "$arch" in
        x86_64)        march="x86_64-linux" ;;
        aarch64|arm64) march="aarch64-linux" ;;
        *) track_failure "mold" "Unsupported arch $arch"; return 0 ;;
    esac

    local name="mold-${ver}-${march}"
    local url="https://github.com/rui314/mold/releases/download/v${ver}/${name}.tar.gz"
    local tmpdir; tmpdir="$(mktemp -d)"

    if ! { curl -fsSL "$url" -o "$tmpdir/mold.tar.gz" && \
           tar -xzf "$tmpdir/mold.tar.gz" -C "$tmpdir" && \
           install -m755 "$tmpdir/$name/bin/mold" "$install_dir/mold" && \
           install -m755 "$tmpdir/$name/bin/mold" "$install_dir/ld.mold"; }; then
        track_failure "mold" "Failed to download/install mold"
        rm -rf "$tmpdir"; return 0
    fi
    rm -rf "$tmpdir"

    # Functional probe: only keep mold if it actually links on this toolchain.
    if command -v rustc &> /dev/null; then
        local probe; probe="$(mktemp -d)"
        echo 'fn main(){}' > "$probe/m.rs"
        if PATH="$install_dir:$PATH" RUSTFLAGS="-C link-arg=-fuse-ld=mold" \
             rustc "$probe/m.rs" -o "$probe/m" &> /dev/null; then
            echo "mold ${ver} installed to $install_dir (link probe OK)."
        else
            rm -f "$install_dir/mold" "$install_dir/ld.mold"
            echo "mold link probe failed on this toolchain; removed (default linker kept)."
        fi
        rm -rf "$probe"
    else
        echo "mold ${ver} installed to $install_dir (rustc absent; skipped link probe)."
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

# Directories that hold BOTH tracked config and runtime state written by the tool
# that owns them. Stow "folds" a directory into a single symlink when the target
# doesn't exist yet — so ~/.copilot became a link straight into the git repo and
# Copilot wrote its session store, command history and sqlite WALs into version
# control. Pre-creating them as real directories forces stow to link the tracked
# children individually and leaves the runtime files in $HOME where they belong.
STOW_NO_FOLD_DIRS=(.copilot)

# Undo an existing fold: ~/<dir> is a symlink INTO the dotfiles repo, so every
# runtime file the owning tool wrote landed in git. Replace the link with a real
# directory and move the untracked files back out of the repo. Tracked files stay
# put and get re-linked by the stow that follows.
_unfold_stow_dir() {
    local d="$1" link="$HOME/$1" target name f
    [[ -L "$link" ]] || return 0
    target=$(cd "$link" 2>/dev/null && pwd -P) || return 0
    # Only touch links that point into a git repo — that's the fold we caused.
    git -C "$target" rev-parse --git-dir >/dev/null 2>&1 || return 0

    echo "→ un-folding ~/$d (symlink into $target)"
    rm "$link" || { track_failure "stow-unfold" "could not remove $link"; return 1; }
    mkdir -p "$link"

    for f in "$target"/*(ND) "$target"/.*(ND); do
        name="${f:t}"
        [[ "$name" == "." || "$name" == ".." ]] && continue
        # Tracked, or a directory containing tracked files → belongs to the repo.
        [[ -n "$(git -C "$target" ls-files -- "$name" 2>/dev/null | head -1)" ]] && continue
        mv "$f" "$link/$name" && echo "    moved $name out of the repo → ~/$d/$name"
    done
}

# Pre-create the real directories so stow links their tracked children
# individually instead of folding the whole directory into one symlink.
_prevent_stow_folding() {
    local d
    for d in "${STOW_NO_FOLD_DIRS[@]}"; do
        _unfold_stow_dir "$d"
        mkdir -p "$HOME/$d"
    done
}

# stow -t $HOME <package>, but conflict-tolerant.
#
# It used to run with --adopt, which does the OPPOSITE of what you want here:
# on a conflict it moves the machine's existing file INTO the repo, overwriting
# the tracked version. That silently reverted committed dotfiles (it ate the
# sccache/mold block from .bashrc and gutted .zshenv's PATH export) and left the
# damage staged for the next commit. The repo is the source of truth, so back the
# local file up instead and let the tracked version win.
_stow_with_backup() {
    local stow_dir="$1" package="$2" label="$3"
    cd "$stow_dir" || { track_failure "$label" "no such directory: $stow_dir"; return 1; }

    local out
    if out=$(stow -vt "$HOME" "$package" 2>&1); then
        [[ -n "$out" ]] && print -r -- "$out"
        return 0
    fi
    print -r -- "$out"

    # "cannot stow <pkg file> over existing target <path> since …" → <path>, relative to $HOME
    local -a conflicts
    conflicts=(${(f)"$(print -r -- "$out" | sed -n 's/.*over existing target \(.*\) since.*/\1/p')"})
    if (( ${#conflicts} == 0 )); then
        track_failure "$label" "stow failed for $package (no recoverable conflicts)"
        return 1
    fi

    local stamp c
    stamp=$(date +%Y%m%d%H%M%S)
    for c in $conflicts; do
        [[ -e "$HOME/$c" && ! -L "$HOME/$c" ]] || continue
        if mv "$HOME/$c" "$HOME/$c.bak-$stamp"; then
            echo "  backed up ~/$c → ~/$c.bak-$stamp (the repo version wins)"
        fi
    done

    if ! stow -vt "$HOME" "$package"; then
        track_failure "$label" "stow failed for $package after backing up conflicts"
        return 1
    fi
}

setup_symlinks() {
    # dotfiles is a bare+worktree repo: stow always from the main worktree so the
    # $HOME symlinks stay stable no matter which worktree you're editing in. Fall
    # back to a flat ~/projects/dotfiles for entrypoints that still clone flat.
    local dotfiles_dir=~/projects/worktree/dotfiles/main
    [ -d "$dotfiles_dir" ] || dotfiles_dir=~/projects/dotfiles

    echo "Stowing dotfiles from $dotfiles_dir..."
    _prevent_stow_folding
    _stow_with_backup "$dotfiles_dir" . "symlinks"
}

# stow is all-or-nothing: one target that already exists as a real file aborts the
# entire tree. On a fresh machine that is routinely a stub some tool wrote before
# setup ran (Claude Code drops a {"theme":"dark"} ~/.claude/settings.json). Back the
# conflicting files up and retry once so the notes tree actually lands.
setup_personal_notes_stow() {
    local stow_dir=~/projects/personal-notes/stow

    if [ ! -d "$stow_dir" ]; then
        echo "personal-notes stow directory not found at $stow_dir — skipping."
        echo "ensure_personal_notes clones it; check the log above for a clone failure."
        return 0
    fi

    echo "Stowing personal-notes from $stow_dir..."
    _stow_with_backup "$stow_dir" home "personal-notes-stow"
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
