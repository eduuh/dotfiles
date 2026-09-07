#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
echo "Script directory: $SCRIPT_DIR"
source "$SCRIPT_DIR/.bin/setup/common.sh"

# --- flags ---
#   --force          re-run every step
#   --profile <tier> override the profile from the prep marker (core|dev|desktop)
#   --work           also install work-machine tools + clone work repos
#   --personal       also clone the personal-only repos (listed in personal-notes)
#   reset            clear recorded step state and exit
SETUP_PROFILE_OVERRIDE=""
SETUP_WORK=false
SETUP_PERSONAL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)     SETUP_FORCE=true; shift ;;
        --profile)   SETUP_PROFILE_OVERRIDE="$2"; shift 2 ;;
        --profile=*) SETUP_PROFILE_OVERRIDE="${1#*=}"; shift ;;
        --work)      SETUP_WORK=true; shift ;;
        --personal)  SETUP_PERSONAL=true; shift ;;
        reset)       reset_steps; exit 0 ;;
        *)           shift ;;
    esac
done

# --- Phase 2: the unattended install. Phase 1 (prep) must have run first. ---
READY_MARKER="$HOME/.local/state/dotfiles/ready"
if [[ ! -f "$READY_MARKER" ]]; then
    echo "No prep marker at $READY_MARKER — the interactive Phase 1 hasn't run."
    echo "Run it first:   ./prep.sh"
    echo "(fresh machine: curl -fsSL https://raw.githubusercontent.com/eduuh/dotfiles/main/bootstrap.sh | bash)"
    exit 1
fi
source "$READY_MARKER"   # sets TARGET, PROFILE
PROFILE="${SETUP_PROFILE_OVERRIDE:-$PROFILE}"   # --profile wins over the marker
echo "Phase 2 · install   target=${TARGET:-?}  profile=${PROFILE:-?}"

# prep cached sudo; keep it alive WITHOUT prompting. Bail if it has lapsed so the
# long install never blocks on a password. Skipped on codespace / root.
SUDO_PID=""
if [[ "$TARGET" != "codespace" && "${EUID:-$(id -u)}" != "0" ]]; then
    if ! sudo -n true 2>/dev/null; then
        echo "sudo credentials not cached — re-run ./prep.sh, then ./setup.sh."
        exit 1
    fi
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_PID=$!
fi

# Project cloning is the slowest part of setup (a large work repo can take hours), and
# nothing else depends on it — so never wait on it. Open the clone as a tmux WINDOW and let
# setup.sh finish: it runs in the session setup.sh was launched from, or — when setup.sh
# isn't inside tmux — in the persistent `planning` session (created if absent). The runner
# (setup-projects.sh) records the `projects` step on completion, so a later run skips it.
_PROJECTS_LOG="${SETUP_STATE_DIR:-$HOME/.local/state/dotfiles}/projects-clone.log"
_PROJECTS_WINDOW="bn-clone"
_PLANNING_SESSION="planning"

_projects_launch() {
    # The marker is per-SHAPE, not just per-step: plain, --personal and --work runs
    # clone different sets. Recording one flat `projects` meant a machine set up
    # without a flag would skip the clone forever, so adding --work later installed
    # the work TOOLS but never cloned the work REPOS. See _projects_step_name.
    local step_name
    step_name=$(_projects_step_name)
    if [[ "$SETUP_FORCE" != "true" ]] && _step_is_done "$step_name"; then
        echo "✓ [$step_name] already done — skipping"
        return 0
    fi
    local runner="$SCRIPT_DIR/setup-projects.sh"
    local -a runner_cmd=("$runner")
    [[ "$SETUP_WORK" == "true" ]] && runner_cmd+=(--work)
    [[ "$SETUP_PERSONAL" == "true" ]] && runner_cmd+=(--personal)

    # No tmux at all: detach with nohup so the clone survives setup.sh exiting.
    if ! command -v tmux >/dev/null 2>&1; then
        mkdir -p "$(dirname "$_PROJECTS_LOG")"
        nohup "${runner_cmd[@]}" > "$_PROJECTS_LOG" 2>&1 < /dev/null &
        echo "→ [projects] cloning in background (no tmux; log: $_PROJECTS_LOG) — setup won't wait."
        return 0
    fi

    # Target the session setup.sh runs in; otherwise the persistent planning session.
    local target
    if [[ -n "$TMUX" ]]; then
        target=$(tmux display-message -p '#S')
    else
        target="$_PLANNING_SESSION"
        tmux has-session -t "$target" 2>/dev/null || tmux new-session -d -s "$target"
    fi

    # Don't open a second clone window if one is already running in that session.
    if tmux list-windows -t "$target" -F '#W' 2>/dev/null | grep -qx "$_PROJECTS_WINDOW"; then
        echo "↻ [projects] clone window '$_PROJECTS_WINDOW' already open in '$target' — leaving it"
        return 0
    fi

    tmux new-window -d -t "$target" -n "$_PROJECTS_WINDOW" "${(j: :)${(q)runner_cmd}}"
    echo "→ [projects] cloning in tmux window '$_PROJECTS_WINDOW' (session '$target') — setup won't wait."
    if [[ -z "$TMUX" ]]; then
        echo "             watch it:  tmux attach -t $target"
    fi
}

# Platform PACKAGE installation for $1 — ALWAYS run (idempotent) so re-running
# setup reconciles newly added packages without SETUP_FORCE. Tool installs live
# in run_platform_setup below and stay resumable/cached.
install_platform_packages() {
    local distro="$1"
    case "$distro" in
        ubuntu|debian) source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"; update_system; install_common_packages; install_ubuntu_specific_packages ;;
        arch)          source "$SCRIPT_DIR/.bin/setup/arch.sh";   install_yay; install_common_packages_arch; install_arch_specific_packages ;;
        fedora)        source "$SCRIPT_DIR/.bin/setup/fedora.sh"; install_fedora_packages ;;
        codespace)     source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"; update_system; install_common_packages ;;
        darwin)        source "$SCRIPT_DIR/.bin/setup/mac.sh";    install_homebrew; install_brew_bundle ;;
        termux)        source "$SCRIPT_DIR/.bin/setup/termux.sh"; update_system; install_common_packages; install_termux_specific_packages ;;
        *) return 2 ;;
    esac
}

# OS-specific TOOL/config setup for $1 (one resumable step). Packages are handled
# separately by install_platform_packages (always-run) before this.
run_platform_setup() {
    local distro="$1"
    case "$distro" in
        ubuntu|debian) source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"; setup_ubuntu ;;
        arch)          source "$SCRIPT_DIR/.bin/setup/arch.sh";   setup_arch ;;
        fedora)        source "$SCRIPT_DIR/.bin/setup/fedora.sh"; setup_fedora ;;
        codespace)     source "$SCRIPT_DIR/.bin/setup/ubuntu.sh"; setup_codespace ;;
        darwin)
            source "$SCRIPT_DIR/.bin/setup/mac.sh"
            setup_kanata_service
            setup_mac
            ;;
        termux)        source "$SCRIPT_DIR/.bin/setup/termux.sh"; setup_termux ;;
        *) return 2 ;;
    esac
}

main() {
    local distro=$(detect_distro)

    case "$distro" in
        ubuntu|debian|arch|fedora|codespace|darwin|termux) ;;
        *) track_failure "distro" "Unsupported distribution: $distro"; print_failure_summary; exit 1 ;;
    esac

    # step <name> <min-profile> <targets> <cmd…> — profile/target filtered,
    # then idempotent + resumable. Records on success; failed steps resume.
    step rust               core wsl,linux,mac,termux install_rust
    step sccache            core wsl,linux,mac install_sccache
    step mold               core wsl,linux     install_mold
    step bn                 core all   setup_bn
    step_always "packages-$distro" core all install_platform_packages "$distro"
    step "platform-$distro" core all   run_platform_setup "$distro"

    # personal-notes always, and synchronously: the detached project clone below is
    # skipped once its marker is recorded, and the work/personal repo setup scripts it
    # runs live inside personal-notes — so this must land first, on every run.
    step_always personal-notes core all ensure_personal_notes

    # Work-machine tools — only with --work, and only AFTER
    # personal-notes, since the installer script lives inside it. step_always, not
    # step: a run that happened before personal-notes existed must not record itself
    # as done and then skip forever.
    if [[ "$SETUP_WORK" == "true" ]]; then
        step_always work-tools core all install_work_tools
    fi

    # tmux comes from the platform packages above (bn's install.sh, in the bn step, builds a
    # newer one when the distro's is below its floor); fire the clone into a detached session
    # now so it runs alongside the remaining tool steps and keeps going after setup exits.
    _projects_launch

    if [ "$distro" != "termux" ]; then
        step tmux-plugins core all   install_tmux_plugins
        step zoxide       core all   install_zoxide
        step starship     core all   install_starship
        step pnpm         dev  all   install_pnpm
        step talosctl     dev  all   install_talosctl
        step git-hooks    core all   setup_git_hooks
        step shell-zsh    core all   change_shell_to_zsh
    fi

    # Clean up sudo keepalive
    [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null

    if [[ "${FEDORA_REBOOT_NEEDED:-0}" == "1" ]]; then
        echo "⚠ Fedora atomic: some packages were layered into the next deployment."
        echo "  Reboot to finalize them:  systemctl reboot"
    fi

    print_failure_summary
}

main
