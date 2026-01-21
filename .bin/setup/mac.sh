#!/bin/zsh

install_homebrew() {
    if command -v brew &> /dev/null; then
        echo "Homebrew is already installed."
        brew update || track_failure "homebrew" "Failed to update Homebrew"
        brew upgrade || track_failure "homebrew" "Failed to upgrade Homebrew packages"
        return 0
    fi

    echo "Installing Homebrew..."
    if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        track_failure "homebrew" "Failed to install Homebrew"
        return 0
    fi

    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    echo "Homebrew installed successfully."
}


install_brew_packages() {
    echo "Installing Homebrew packages..."

    # Helper function to install brew package with error tracking
    install_brew_pkg() {
        local pkg="$1"
        local is_cask="${2:-false}"

        if [[ "$is_cask" == "true" ]]; then
            if ! brew install --cask "$pkg" 2>&1; then
                track_failure "brew-cask" "Failed to install cask: $pkg"
            fi
        else
            if ! brew install "$pkg" 2>&1; then
                track_failure "brew" "Failed to install: $pkg"
            fi
        fi
    }

    install_brew_pkg "koekeishiya/formulae/skhd"
    install_brew_pkg "nikitabobko/tap/aerospace" true
    install_brew_pkg "karabiner-elements" true

    # Start skhd service
    echo "Starting skhd service..."
    skhd --start-service || echo "Failed to start skhd service (it might be already running or require permissions), continuing..."

    brew tap FelixKratz/formulae || track_failure "brew" "Failed to tap FelixKratz/formulae"
    install_brew_pkg "sketchybar"

    # Install common software packages
    for software in "${common_software[@]}"; do
        echo "Installing $software..."
        install_brew_pkg "$software"
    done

    # Mac-specific packages
    local mac_software=(
        coreutils moreutils findutils bash bash-completion2 wget
        openssh screen git-lfs lua pv p7zip pigz rename ssh-copy-id
        vbindiff zopfli gnu-sed node deno hugo bat zoxide tree jq
        imagemagick pkg-config pngpaste kanata
        jesseduffield/lazydocker/lazydocker kubernetes-cli 1password-cli
        fluxcd/tap/flux
    )

    for software in "${mac_software[@]}"; do
        echo "Checking for updates for $software..."
        if brew list "$software" &>/dev/null; then
            if brew outdated | grep -q "^$software"; then
                echo "Updating $software..."
                brew upgrade "$software" >/dev/null 2>&1 || track_failure "brew" "Failed to upgrade: $software"
            else
                echo "$software is up-to-date."
            fi
        else
            echo "Installing $software..."
            install_brew_pkg "$software"
        fi
    done
}

install_brew_casks() {
    echo "Installing Homebrew casks..."

    local mac_casks=(
        alacritty karabiner-elements kitty
        font-fira-code-nerd-font docker spotify
    )

    for cask in "${mac_casks[@]}"; do
        echo "Installing $cask..."
        if ! brew install --cask "$cask" 2>&1; then
            track_failure "brew-cask" "Failed to install cask: $cask"
        fi
    done
}

###########################################
# macOS specific setup
###########################################

setup_mac_python() {
    echo "Setting up Python environment for macOS..."

    if ! command -v pyenv &> /dev/null; then
        echo "Installing pyenv..."
        if ! brew install pyenv; then
            track_failure "python" "Failed to install pyenv"
            return 0
        fi
    else
        echo "pyenv is already installed."
    fi

    if ! pyenv versions | grep -q "3.12.0"; then
        echo "Installing Python 3.12.0..."
        if ! pyenv install 3.12.0; then
            track_failure "python" "Failed to install Python 3.12.0 via pyenv"
            return 0
        fi
    else
        echo "Python 3.12.0 is already installed."
    fi

    pyenv global 3.12.0

    if [ ! -d "$HOME/.local/state/python3" ]; then
        echo "Creating Python virtual environment..."
        if ! python3 -m venv ~/.local/state/python3; then
            track_failure "python" "Failed to create Python virtual environment"
            return 0
        fi
    else
        echo "Python virtual environment already exists."
    fi

    source ~/.local/state/python3/bin/activate
    if ! pip install --upgrade pip pynvim requests; then
        track_failure "python" "Failed to install Python packages"
    fi

    if ! command -v bun &> /dev/null; then
        echo "Installing Bun JavaScript runtime..."
        if ! curl -fsSL https://bun.sh/install | BUN_INSTALL=yes bash; then
            track_failure "bun" "Failed to install Bun"
        fi
    else
        echo "Bun is already installed."
    fi
}

setup_mac_security() {
    echo "Configuring macOS security settings..."

    # Disable Gatekeeper to allow apps from unidentified developers
    # Note: This is a security setting - only do this if you understand the implications
    if ! sudo spctl --master-disable; then
        track_failure "security" "Failed to disable Gatekeeper"
    fi
}

setup_kanata_service() {
    echo "Setting up Kanata service..."
    local kanata_path="$(brew --prefix)/bin/kanata"
    local config_path="$HOME/.config/keyboard/colemak.kbd"

    if [ ! -f "$kanata_path" ]; then
        track_failure "kanata" "Kanata binary not found at $kanata_path"
        return 0
    fi

    if [ ! -f "$config_path" ]; then
        track_failure "kanata" "Kanata config not found at $config_path"
        return 0
    fi

    # Create the plist file
    cat <<EOF > /tmp/com.custom.kanata.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.custom.kanata</string>
    <key>ProgramArguments</key>
    <array>
        <string>$kanata_path</string>
        <string>--cfg</string>
        <string>$config_path</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/kanata.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/kanata.err</string>
</dict>
</plist>
EOF

    # Install the plist
    echo "Installing LaunchDaemon (requires sudo)..."
    if ! sudo mv /tmp/com.custom.kanata.plist /Library/LaunchDaemons/com.custom.kanata.plist; then
        track_failure "kanata" "Failed to install kanata LaunchDaemon"
        return 0
    fi

    sudo chown root:wheel /Library/LaunchDaemons/com.custom.kanata.plist
    sudo chmod 644 /Library/LaunchDaemons/com.custom.kanata.plist

    # Load the service
    sudo launchctl unload /Library/LaunchDaemons/com.custom.kanata.plist 2>/dev/null || true
    if ! sudo launchctl load /Library/LaunchDaemons/com.custom.kanata.plist; then
        track_failure "kanata" "Failed to load kanata service"
        return 0
    fi

    echo "Kanata service installed and started."
}

setup_mac() {
    install_homebrew
    install_brew_packages
    install_brew_casks
    install_lazygit
    install_claude_code
    setup_mac_python
    setup_symlinks
    setup_mac_security
    setup_kanata_service
}
