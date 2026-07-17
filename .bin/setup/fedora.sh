#!/bin/zsh
# Fedora platform setup. Handles BOTH flavours of Fedora:
#   * traditional (Workstation/Server/Spins) — mutable /usr, packages via dnf.
#   * atomic / rpm-ostree (Silverblue, Kinoite, COSMIC Atomic, …) — /usr is
#     read-only and host packages are LAYERED with rpm-ostree instead of dnf.
# The distinction is made once by _fedora_is_atomic and everything routes through
# fedora_pkg_install so the rest of the setup doesn't care which flavour it's on.

# rpm-ostree systems ship an /run/ostree-booted marker; that's the canonical test.
_fedora_is_atomic() {
    [[ -f /run/ostree-booted ]]
}

# fedora_pkg_install <pkg…> — install host packages the right way for this flavour.
#   Atomic:      layer with rpm-ostree. --apply-live lands them on the RUNNING
#                system with no reboot; --idempotent skips already-layered pkgs;
#                --allow-inactive lets us request pkgs already provided by the
#                base image without erroring. Layering is expensive per call, so
#                callers should batch everything into ONE invocation.
#   Traditional: plain `dnf install`.
fedora_pkg_install() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return 0

    if _fedora_is_atomic; then
        echo "Layering packages via rpm-ostree (atomic Fedora): ${pkgs[*]}"
        if sudo rpm-ostree install --idempotent --allow-inactive --apply-live -y "${pkgs[@]}"; then
            return 0
        fi
        # --apply-live can fail even when the packages layer cleanly into the
        # NEXT deployment (live-apply has known limitations). Retry as a plain
        # layering op; if that succeeds the packages are staged and a reboot
        # finalizes them — so we treat it as success and flag a reboot.
        echo "live-apply failed; retrying as plain layering (a reboot will finalize)…"
        if sudo rpm-ostree install --idempotent --allow-inactive -y "${pkgs[@]}"; then
            FEDORA_REBOOT_NEEDED=1
            echo "⚠ packages layered into the next deployment — reboot to finalize."
            return 0
        fi
        track_failure "rpm-ostree" "Failed to layer packages: ${pkgs[*]}"
        return 1
    else
        echo "Installing packages via dnf: ${pkgs[*]}"
        if ! sudo dnf install -y "${pkgs[@]}"; then
            track_failure "dnf" "Failed to install packages: ${pkgs[*]}"
            return 1
        fi
    fi
}

# The shared common_software list uses names that all exist verbatim in Fedora
# repos (git stow make cmake ripgrep tmux zsh unzip tree jq). Fedora-specific
# extras cover man pages, secret storage, and the toolchain that the from-source
# tmux fallback (ensure_tmux_version) needs. neovim + fzf are intentionally NOT
# layered here — install_neovim/install_fzf fetch newer builds into ~/.local/bin.
install_fedora_packages() {
    local fedora_extras=(
        gcc bison pkgconf-pkg-config
        libevent-devel ncurses-devel
        man-db man-pages
        libsecret curl fd-find bat
    )
    # One transaction: cheap on dnf, essential on rpm-ostree.
    fedora_pkg_install "${common_software[@]}" "${fedora_extras[@]}"
}

setup_fedora() {
    ensure_tmux_version      # Fedora repo tmux (>=3.5) satisfies the floor; no source build
    install_neovim
    install_fzf
    install_nvm
    install_lazygit
    install_claude_code
    install_playwright
    setup_python
    setup_symlinks
}
