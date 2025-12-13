#!/bin/zsh

install_homebrew() {
    if command -v brew &> /dev/null; then
        echo "Homebrew is already installed."
        brew update
        brew upgrade
        return 0
    fi

    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    echo "Homebrew installed successfully."
}


install_brew_packages() {
    echo "Installing Homebrew packages..."
    brew install koekeishiya/formulae/skhd
    brew install --cask nikitabobko/tap/aerospace
    brew install --cask karabiner-elements
    
    # Start skhd service
    echo "Starting skhd service..."
    skhd --start-service || echo "Failed to start skhd service (it might be already running or require permissions), continuing..."

    brew tap FelixKratz/formulae
    brew install sketchybar

    # Install common software packages
    for software in "${common_software[@]}"; do
        echo "Installing $software..."
        brew install "$software"
    done

    # Mac-specific packages
    local mac_software=(
        coreutils moreutils findutils bash bash-completion2 wget
        openssh screen git-lfs lua pv p7zip pigz rename ssh-copy-id
        vbindiff zopfli gnu-sed node deno hugo bat
        imagemagick pkg-config pngpaste kanata
        jesseduffield/lazydocker/lazydocker kubernetes-cli 1password-cli
        fluxcd/tap/flux
    )

    for software in "${mac_software[@]}"; do
        echo "Checking for updates for $software..."
        if brew list "$software" &>/dev/null; then
            if brew outdated | grep -q "^$software"; then
                echo "Updating $software..."
                brew upgrade "$software" >/dev/null 2>&1
            else
                echo "$software is up-to-date."
            fi
        else
            echo "Installing $software..."
            brew install "$software"
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
        brew install --cask "$cask"
    done
}

###########################################
# macOS specific setup
###########################################

setup_mac_python() {
    echo "Setting up Python environment for macOS..."

    if ! command -v pyenv &> /dev/null; then
        echo "Installing pyenv..."
        brew install pyenv
    else
        echo "pyenv is already installed."
    fi

    if ! pyenv versions | grep -q "3.12.0"; then
        echo "Installing Python 3.12.0..."
        pyenv install 3.12.0
    else
        echo "Python 3.12.0 is already installed."
    fi

    pyenv global 3.12.0

    if [ ! -d "$HOME/.local/state/python3" ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv ~/.local/state/python3
    else
        echo "Python virtual environment already exists."
    fi

    source ~/.local/state/python3/bin/activate
    pip install --upgrade pip pynvim requests

    if ! command -v bun &> /dev/null; then
        echo "Installing Bun JavaScript runtime..."
        curl -fsSL https://bun.sh/install | BUN_INSTALL=yes bash
    else
        echo "Bun is already installed."
    fi
}

setup_mac_security() {
    echo "Configuring macOS security settings..."

    # Disable Gatekeeper to allow apps from unidentified developers
    # Note: This is a security setting - only do this if you understand the implications
    sudo spctl --master-disable
}

setup_kanata_service() {
    echo "Setting up Kanata service..."
    local kanata_path="$(brew --prefix)/bin/kanata"
    local config_path="$HOME/.config/keyboard/colemak.kbd"

    if [ ! -f "$kanata_path" ]; then
        echo "Kanata binary not found at $kanata_path"
        return 1
    fi

    if [ ! -f "$config_path" ]; then
        echo "Kanata config not found at $config_path"
        return 1
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
    sudo mv /tmp/com.custom.kanata.plist /Library/LaunchDaemons/com.custom.kanata.plist
    sudo chown root:wheel /Library/LaunchDaemons/com.custom.kanata.plist
    sudo chmod 644 /Library/LaunchDaemons/com.custom.kanata.plist
    
    # Load the service
    sudo launchctl unload /Library/LaunchDaemons/com.custom.kanata.plist 2>/dev/null || true
    sudo launchctl load /Library/LaunchDaemons/com.custom.kanata.plist
    
    echo "Kanata service installed and started."
}

setup_mac() {
    install_homebrew
    install_brew_packages
    install_brew_casks
    install_lazygit
    setup_mac_python
    setup_symlinks
    setup_mac_security
    setup_kanata_service
}
