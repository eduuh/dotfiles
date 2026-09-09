# windows-side.ps1 - the Windows half of a WSL machine's setup.
#
# Runs on the WINDOWS side, launched by setup_windows_side() in windows.sh via
# powershell.exe. It performs the non-Administrator steps of win-dot's readme
# (steps 1, 2, 5 and 6) against an already-cloned win-dot:
#
#   1. install or update Scoop
#   2. install Windows git (scoop) - win-dot's own scripts shell out to it
#   5. scripts/install.ps1    - scoop/winget packages + PowerShell profile stubs
#   6. scripts/setup-git.ps1  - checks the clone out over $HOME, wiring `dot`
#
# Step 3 (cloning win-dot) is dotfiles' clone_repos, which routes the repo onto
# the Windows filesystem. Step 4 (scripts/run.ps1) needs Administrator and is
# handled separately - see setup_windows_admin().
#
# Idempotent: every step is skip-if-present or safe to repeat, so setup.sh can
# re-run it on every pass.
#
# Non-ASCII is safe here only because _run_windows_ps1 stages this file with a
# UTF-8 BOM; see the comment there for what happens without one.

[CmdletBinding()]
param(
    # Windows-form path to the win-dot clone, e.g. C:\Users\me\projects\win-dot.
    [Parameter(Mandatory)][string]$Repo,
    # Pass through to install.ps1; installs the Keyflow keyboard layout too.
    [switch]$InstallKeyboard,
    # Windows path to windows-askpass.cmd, which answers git's credential prompts
    # from $env:DOTFILES_GH_TOKEN. Optional: without it the private submodule below
    # simply fails to clone, and the rest of the run still stands.
    [string]$AskPass
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

function Info($msg) { Write-Host "[windows-side] $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[windows-side] $msg" -ForegroundColor Green }

if (-not (Test-Path $Repo)) {
    Write-Error "win-dot clone not found at $Repo - clone_repos should have created it."
    exit 1
}

# Scoop refuses to install under an elevated shell, and win-dot's readme is
# explicit that these steps want a normal window. WSL's powershell.exe is
# unelevated, so this only trips if someone runs the script by hand.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Error "Running as Administrator; scoop and the package install must run unelevated."
    exit 1
}

# --- 1. Scoop -------------------------------------------------------------
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Info 'installing Scoop...'
    if ((Get-ExecutionPolicy -Scope CurrentUser) -in @('Restricted', 'Undefined')) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    }
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    # The installer extends PATH for future shells only; make it usable in this one.
    $env:PATH = "$HOME\scoop\shims;$env:PATH"
    Ok 'Scoop installed'
} else {
    Info 'updating Scoop...'
    # A stale bucket makes the package install below fail on packages that exist;
    # a failing `scoop update` (usually a git hiccup) should not sink the run.
    try { scoop update } catch { Write-Warning "scoop update failed: $($_.Exception.Message)" }
}

# --- 2. Windows git -------------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Info 'installing git...'
    scoop install git
    Ok 'git installed'
} else {
    Info "git present: $((Get-Command git).Source)"
}

# --- 5. Packages + profile stubs -----------------------------------------
Info 'running win-dot scripts/install.ps1...'
& "$Repo\scripts\install.ps1" -InstallKeyboard:$InstallKeyboard
if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Error "install.ps1 exited $LASTEXITCODE"
    exit $LASTEXITCODE
}

# --- 6. The `dot` command -------------------------------------------------
# This checks the clone out over $HOME (--work-tree=$HOME --force), so it lands
# .wslconfig, .gitconfig, the PowerShell profile and the Windows Terminal and
# GlazeWM configs in the places those applications read them from. It also inits
# win-dot's submodules, one of which is private.
#
# Windows git's credential helper is GCM, which holds no github.com login here
# and cannot prompt for one with no console attached - so git fell through to its
# built-in terminal prompt, which needs /dev/tty and died with "No such device or
# address", failing the submodule clone and with it the whole script.
#
# GIT_ASKPASS is the documented hook for that fallback. GIT_TERMINAL_PROMPT=0 stops
# git reaching for a terminal at all if the askpass is missing, so the failure stays
# a clean error instead of another /dev/tty crash.
if ($AskPass -and (Test-Path $AskPass) -and $env:DOTFILES_GH_TOKEN) {
    $env:GIT_ASKPASS = $AskPass
    $env:GIT_TERMINAL_PROMPT = '0'
} else {
    Info 'no askpass/token - win-dot private submodules will be skipped'
}

Info 'running win-dot scripts/setup-git.ps1...'
try {
    & "$Repo\scripts\setup-git.ps1"
}
finally {
    # Drop the borrowed credentials again so nothing after this runs with them.
    Remove-Item Env:GIT_ASKPASS, Env:GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue
}
if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Error "setup-git.ps1 exited $LASTEXITCODE"
    exit $LASTEXITCODE
}

Ok 'Windows side configured. Restart PowerShell to pick up the profile.'
exit 0
