#!/bin/zsh

# Kanata as a systemd USER service, without sudo: it only needs to read the
# keyboards (input group) and create a virtual one (/dev/uinput). The uinput node
# is root-only by default, so a udev rule hands it to a uinput group. Group
# membership only applies to new logins — on the first run the service can't open
# the devices until you log out and back in (or reboot); it starts on its own then.
setup_kanata_linux() {
    local kanata_path config_path="$HOME/.config/keyboard/colemak.kbd"
    local unit_dir="$HOME/.config/systemd/user"
    # Skip ~/.bin: it holds a same-named wrapper script.
    kanata_path=$(path=(${path:#$HOME/.bin}); command -v kanata) || {
        track_failure "kanata" "kanata binary not found — is the AUR package installed?"
        return 0
    }
    if [[ ! -f "$config_path" ]]; then
        track_failure "kanata" "Kanata config not found at $config_path"
        return 0
    fi

    getent group uinput > /dev/null || sudo groupadd --system uinput \
        || { track_failure "kanata" "Failed to create uinput group"; return 0; }
    sudo usermod -aG input,uinput "$USER" \
        || { track_failure "kanata" "Failed to add $USER to input/uinput groups"; return 0; }

    echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' \
        | sudo tee /etc/udev/rules.d/99-kanata-uinput.rules > /dev/null
    echo uinput | sudo tee /etc/modules-load.d/uinput.conf > /dev/null
    sudo modprobe uinput
    sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=uinput

    # Replaces the old NOPASSWD sudoers entry, which nothing needs any more.
    sudo rm -f /etc/sudoers.d/kanata

    mkdir -p "$unit_dir"
    cat > "$unit_dir/kanata.service" <<UNIT
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Type=simple
ExecStart=$kanata_path --cfg $config_path
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
UNIT

    systemctl --user daemon-reload
    if ! systemctl --user enable kanata.service; then
        track_failure "kanata" "Failed to enable kanata service"
        return 0
    fi
    # Expected to fail on the first run (groups not active yet) — not a failure.
    if ! systemctl --user restart kanata.service 2>/dev/null; then
        echo "kanata installed — log out and back in (or reboot) to activate it."
    fi
}

install_yay() {
    if command -v yay &> /dev/null; then
        echo "Yay AUR helper is already installed."
        return 0
    fi

    echo "Installing Yay AUR helper..."
    if ! sudo pacman -S --needed --noconfirm git base-devel; then
        track_failure "pacman" "Failed to install git and base-devel"
        return 0
    fi

    if ! git clone https://aur.archlinux.org/yay.git /tmp/yay; then
        track_failure "yay" "Failed to clone yay repository"
        return 0
    fi

    cd /tmp/yay
    if ! makepkg -si --noconfirm; then
        cd - > /dev/null
        rm -rf /tmp/yay
        track_failure "yay" "Failed to build and install yay"
        return 0
    fi
    cd - > /dev/null
    rm -rf /tmp/yay
    echo "Yay AUR helper installed successfully."
}

install_common_packages_arch() {
    echo "Installing common packages..."

    for pkg in "${common_software[@]}"; do
        if ! yay -Qi "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            if ! yay -S --noconfirm "$pkg"; then
                track_failure "yay" "Failed to install: $pkg"
            fi
        else
            echo "$pkg is already installed."
        fi
    done
}

install_nordpass_cli() {
    local install_dir="$HOME/.local/bin"
    if [[ -x "$install_dir/np" ]]; then
        echo "NordPass CLI is already installed."
        return 0
    fi

    local installer
    installer=$(mktemp) || {
        track_failure "nordpass-cli" "Failed to create installer download"
        return 0
    }

    # The official installer verifies its signed manifest and binary checksum.
    if ! { curl --proto '=https' --tlsv1.2 -fsSL https://downloads.npass.app/cli/install.sh -o "$installer" &&
        NORDPASS_CLI_INSTALL_DIR="$install_dir" bash "$installer"; }; then
        track_failure "nordpass-cli" "Failed to install NordPass CLI"
    fi
    rm -f -- "$installer"
}

setup_surfshark_linux() {
    if ! command -v surfshark &> /dev/null; then
        track_failure "surfshark" "Surfshark binary not found — is the AUR package installed?"
        return 0
    fi

    if systemctl is-enabled --quiet surfsharkd2.service &&
        systemctl is-active --quiet surfsharkd2.service; then
        return 0
    fi

    if ! { sudo systemctl daemon-reload &&
        sudo systemctl enable --now surfsharkd2.service; }; then
        track_failure "surfshark" "Failed to enable the Surfshark service"
    fi
}

install_arch_specific_packages() {
    echo "Installing Arch-specific packages..."

    local arch_packages=(
        man-db man-pages libsecret acpi d2 bat lua curl kanata 1password nordpass-bin surfshark-client gcc python
        bubblewrap socat strace shfmt
        podman icu krb5 openssl zlib
        kdenlive obs-studio thunderbird
        wl-clipboard xclip   # clipboard provider for nvim's unnamedplus
    )

    for pkg in "${arch_packages[@]}"; do
        if ! yay -Qi "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            if yay -S --noconfirm "$pkg"; then
                continue
            fi
            # Omarchy pins pacman to a snapshot mirror that can drop files its
            # database still lists (d2 404'd). mise fetches upstream releases.
            if command -v mise &> /dev/null && mise registry "$pkg" &> /dev/null \
                && mise use -g "$pkg@latest"; then
                echo "Installed $pkg via mise instead."
            else
                track_failure "yay" "Failed to install: $pkg"
            fi
        else
            echo "$pkg is already installed."
        fi
    done

    install_nordpass_cli
    setup_surfshark_linux
}

setup_arch() {
    install_nvm
    install_neovim
    install_fzf

    install_lazygit
    install_claude_code
    install_copilot_cli
    install_playwright
    setup_python
    # setup_symlinks is NOT called here any more: it is its own step_always in
    # setup.sh, so a failure in this function can no longer cost every symlink.
    setup_kanata_linux
}
