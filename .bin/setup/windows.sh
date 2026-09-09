#!/bin/zsh
# windows.sh — drives the Windows half of a WSL machine's setup.
#
# On WSL, dotfiles only configures Linux; everything a Windows application reads
# (PowerShell profile, Windows Terminal, GlazeWM, VS Code, .wslconfig) lives in
# eduuh/win-dot, on the Windows filesystem. clone_repos already puts that repo
# there — see WINDOWS_CLONE_REPOS — but a clone is not an install: the packages,
# the profile stubs and the `dot` command all come from win-dot's own PowerShell
# scripts, which have to run on the Windows side.
#
# So this is the bridge: hand .bin/setup/windows-side.ps1 to powershell.exe and
# let it run win-dot's installers in place.
#
# Sourced by common.sh; the entry points are setup_windows_side (unattended, runs
# on every setup) and setup_windows_admin (opt-in, needs UAC).

# ${(%):-%x} resolves this file's own path even though common.sh sources it —
# ${0:A:h} would give the *caller's* script instead, so the .ps1 beside this file
# could not be found.
_WINDOWS_SH_DIR="${${(%):-%x}:A:h}"

# powershell.exe, absolute. `command -v` would depend on WSL interop having put
# /mnt/c/Windows/System32 on PATH, which a trimmed PATH or a WSL_INTEROP hiccup
# takes away — and then the whole step silently no-ops on a machine that has it.
_WINDOWS_POWERSHELL="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"

_find_powershell() {
    [ -x "$_WINDOWS_POWERSHELL" ] && { echo "$_WINDOWS_POWERSHELL"; return 0; }
    local p
    p=$(command -v powershell.exe 2>/dev/null) && { echo "$p"; return 0; }
    return 1
}

# Copy one helper file from this directory to the Windows temp dir and echo its
# Windows path. Callers hand that path to powershell.exe.
#
# Copying rather than pointing at it in place: these files live in the WSL
# filesystem, which Windows reaches only over a \\wsl.localhost\ UNC path, and
# powershell.exe refuses a UNC working directory — -File against one warns and then
# misbehaves.
#
# Two encoding fixes are applied on the way, both of which cost a real debugging
# session to find:
#
#   .ps1 gets a UTF-8 BOM. Windows PowerShell 5.1 — what WSL interop gives us —
#   decodes a BOM-less file as the system ANSI codepage, so an em dash in a comment
#   became three cp1252 characters ending in a RIGHT DOUBLE QUOTE. PowerShell takes
#   smart quotes as real string delimiters, so it closed a string early and failed
#   60 lines later on "Missing closing '}'".
#
#   .cmd gets CRLF. cmd.exe parses a batch file line by line as it runs it, and an
#   LF-only if/else block is a documented way to get "The syntax of the command is
#   incorrect" from a file that looks perfectly valid.
_stage_windows_file() {
    local name="$1"
    local src="$_WINDOWS_SH_DIR/$name"
    [ -f "$src" ] || { track_failure "windows-side" "missing $src"; return 1; }

    local profile
    profile=$(_windows_user_profile) || {
        track_failure "windows-side" "could not resolve the Windows user profile"
        return 1
    }
    local staging="$profile/AppData/Local/Temp/dotfiles-setup"
    mkdir -p "$staging" || { track_failure "windows-side" "could not create $staging"; return 1; }

    case "$name" in
        *.ps1) { printf '\xEF\xBB\xBF'; cat "$src"; } > "$staging/$name" ;;
        *.cmd) sed 's/$/\r/' "$src" > "$staging/$name" ;;
        *)     cat "$src" > "$staging/$name" ;;
    esac || { track_failure "windows-side" "could not stage $name"; return 1; }

    wslpath -w "$staging/$name" || {
        track_failure "windows-side" "wslpath failed for $staging/$name"
        return 1
    }
}

# Run a staged .ps1 on the Windows side, forwarding any extra args.
_run_windows_ps1() {
    local script_name="$1"; shift

    local pwsh
    pwsh=$(_find_powershell) || {
        echo "· [windows-side] powershell.exe not found — is WSL interop disabled?"
        return 1
    }

    local profile
    profile=$(_windows_user_profile) || {
        track_failure "windows-side" "could not resolve the Windows user profile"
        return 1
    }

    local win_script
    win_script=$(_stage_windows_file "$script_name") || return 1

    # cd onto the Windows filesystem first: launched from a Linux cwd, powershell.exe
    # prints a UNC warning and silently lands in C:\Windows.
    ( cd "$profile" && "$pwsh" -NoProfile -ExecutionPolicy Bypass -File "$win_script" "$@" )
}

# Non-Administrator Windows setup — win-dot readme steps 1, 2, 5 and 6.
# Idempotent, so setup.sh runs it on every pass (step_always).
setup_windows_side() {
    _is_wsl || return 0

    local repo_dir
    repo_dir=$(_regular_clone_target win-dot)
    if [ ! -d "$repo_dir/.git" ]; then
        # Not a failure: clone_repos runs detached and may still be working, and
        # the next setup run picks this up. Say so rather than failing the run.
        echo "· [windows-side] no win-dot clone at $repo_dir yet — skipping (re-run setup once the clone finishes)"
        return 0
    fi

    local win_repo
    win_repo=$(wslpath -w "$repo_dir") || {
        track_failure "windows-side" "wslpath failed for $repo_dir"
        return 1
    }

    local -a args=(-Repo "$win_repo")
    [[ "${SETUP_WINDOWS_KEYBOARD:-false}" == "true" ]] && args+=(-InstallKeyboard)

    # win-dot pulls in a PRIVATE submodule (.bin/tmux-workflow). Windows git has
    # GCM as its credential helper, but GCM holds no github.com login here and
    # cannot prompt for one with no console attached — so it fell through to git's
    # prompt script, which died on "/dev/tty: No such device or address" and took
    # setup-git.ps1 down with it.
    #
    # Lend the Windows side the personal account's gh token for the duration of the
    # run, through the environment — WSLENV forwards it into the Windows process.
    # Never argv or a file: a token on a command line is visible to every other
    # process on the box, and one in a config file outlives the run.
    #
    # It is spent by windows-askpass.cmd, via GIT_ASKPASS. The obvious alternative,
    # resetting credential.helper with an empty GIT_CONFIG_VALUE_0 the way
    # setup-work-repos.sh does in WSL, CANNOT work here: Windows cannot hold an
    # empty environment variable at all — PowerShell deletes the variable instead of
    # emptying it — so git saw GIT_CONFIG_COUNT=2 with a missing value and refused
    # the whole config with "fatal: unable to parse command-line config".
    local gh_token=""
    if command -v gh >/dev/null 2>&1; then
        gh_token=$(gh auth token -u "${GH_PERSONAL_ACCOUNT:-eduuh}" 2>/dev/null)
    fi
    if [[ -z "$gh_token" ]]; then
        echo "· [windows-side] no ${GH_PERSONAL_ACCOUNT:-eduuh} gh token — win-dot's private submodule will not clone"
    fi

    local win_askpass
    win_askpass=$(_stage_windows_file windows-askpass.cmd) || return 1
    args+=(-AskPass "$win_askpass")

    DOTFILES_GH_TOKEN="$gh_token" \
    WSLENV="${WSLENV:+$WSLENV:}DOTFILES_GH_TOKEN" \
    _run_windows_ps1 windows-side.ps1 "${args[@]}" || {
        track_failure "windows-side" "windows-side.ps1 failed"
        return 1
    }
    echo "✓ [windows-side] win-dot installed from $repo_dir"
}

# Administrator Windows setup — win-dot readme step 4 (scripts/run.ps1: Developer
# Mode, the WSL and VirtualMachinePlatform features).
#
# Deliberately NOT part of the default run. It self-elevates through UAC and then
# asks its own Y/N question, so it cannot complete unattended — and setup.sh's
# Phase 2 is the unattended phase. It is also very nearly a no-op from inside WSL:
# reaching this code at all means the WSL features it enables are already on.
# Run it with ./setup.sh --windows-admin, and answer the two prompts.
setup_windows_admin() {
    _is_wsl || return 0

    local repo_dir
    repo_dir=$(_regular_clone_target win-dot)
    [ -d "$repo_dir/.git" ] || {
        echo "· [windows-admin] no win-dot clone at $repo_dir — skipping"
        return 0
    }

    local pwsh win_script
    pwsh=$(_find_powershell) || { echo "· [windows-admin] powershell.exe not found"; return 1; }
    win_script=$(wslpath -w "$repo_dir/scripts/run.ps1") || return 1

    echo "→ [windows-admin] launching win-dot run.ps1 — accept the UAC prompt, then answer Y."
    ( cd "$repo_dir" && "$pwsh" -NoProfile -ExecutionPolicy Bypass -File "$win_script" ) || {
        track_failure "windows-admin" "run.ps1 failed or was declined"
        return 1
    }
}
