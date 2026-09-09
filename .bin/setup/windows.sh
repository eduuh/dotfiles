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

# Run a repo-local .ps1 on the Windows side, forwarding any extra args.
#
# The script lives in the WSL filesystem, which Windows can only reach over a
# \\wsl.localhost\ UNC path — and powershell.exe refuses to use a UNC path as its
# working directory, so -File against one warns and then misbehaves. Copying the
# script to the Windows temp dir sidesteps that entirely, and costs a few KB.
_run_windows_ps1() {
    local script_name="$1"; shift
    local src="$_WINDOWS_SH_DIR/$script_name"
    [ -f "$src" ] || { track_failure "windows-side" "missing $src"; return 1; }

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

    local staging="$profile/AppData/Local/Temp/dotfiles-setup"
    mkdir -p "$staging" || { track_failure "windows-side" "could not create $staging"; return 1; }

    # Stage WITH a UTF-8 BOM. Windows PowerShell 5.1 - which is what WSL interop
    # gives us - decodes a BOM-less file as the system ANSI codepage, not UTF-8.
    # An em dash in a comment then decodes to three cp1252 characters, the last of
    # which is a RIGHT DOUBLE QUOTE; PowerShell accepts smart quotes as genuine
    # string delimiters, so it ended a string early and died 60 lines later on a
    # "Missing closing '}'" that had nothing to do with braces. The BOM makes the
    # decoding explicit, so the script can hold any character it likes.
    { printf '\xEF\xBB\xBF'; cat "$src"; } > "$staging/$script_name" \
        || { track_failure "windows-side" "could not stage $script_name"; return 1; }

    local win_script
    win_script=$(wslpath -w "$staging/$script_name") || {
        track_failure "windows-side" "wslpath failed for $staging/$script_name"
        return 1
    }

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
