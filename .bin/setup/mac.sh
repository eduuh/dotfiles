#!/bin/zsh

install_homebrew() {
    if command -v brew &> /dev/null; then
        echo "Homebrew is already installed."
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

install_brew_bundle() {
    echo "Installing Homebrew packages via Brewfile..."
    local brewfile="$SCRIPT_DIR/Brewfile"

    if [ ! -f "$brewfile" ]; then
        track_failure "brew" "Brewfile not found at $brewfile"
        return 0
    fi

    if ! brew bundle install --file="$brewfile"; then
        track_failure "brew" "brew bundle install failed (some packages may have installed)"
    fi

    # Start skhd service
    skhd --start-service 2>/dev/null || true
}

###########################################
# macOS specific setup
###########################################

setup_mac_python() {
    echo "Setting up Python environment for macOS..."

    # Use Homebrew's pre-built Python instead of compiling via pyenv
    if ! brew list python@3.12 &>/dev/null; then
        echo "Installing Python 3.12 via Homebrew..."
        if ! brew install python@3.12; then
            track_failure "python" "Failed to install Python 3.12 via Homebrew"
            return 0
        fi
    else
        echo "Python 3.12 is already installed via Homebrew."
    fi

    local python_bin="$(brew --prefix python@3.12)/bin/python3.12"

    if [ ! -d "$HOME/.local/state/python3" ]; then
        echo "Creating Python virtual environment..."
        if ! "$python_bin" -m venv ~/.local/state/python3; then
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
    # Homebrew, brew bundle, and kanata are already called from setup.sh
    install_claude_code
    setup_mac_python
    setup_symlinks
}
