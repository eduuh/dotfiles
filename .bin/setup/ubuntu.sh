#!/bin/zsh

update_system() {
    echo "Updating package list and upgrading installed packages..."
    if ! sudo apt-get update -y; then
        track_failure "apt" "Failed to update package list"
    fi
    if ! sudo apt-get upgrade -y; then
        track_failure "apt" "Failed to upgrade packages"
    fi
    if ! sudo apt-get install software-properties-common -y; then
        track_failure "apt" "Failed to install software-properties-common"
    fi
}

install_common_packages() {
    echo "Installing common packages..."

    for pkg in "${common_software[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            if ! sudo apt-get install -y "$pkg"; then
                track_failure "apt" "Failed to install: $pkg"
            fi
        else
            echo "$pkg is already installed."
        fi
    done
}

install_ubuntu_specific_packages() {
    echo "Installing Ubuntu-specific packages..."

    local ubuntu_packages=(
        manpages-dev man-db manpages-posix-dev
        libsecret-1-dev gnome-keyring default-jre libgbm-dev
    )

    for pkg in "${ubuntu_packages[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "Installing $pkg..."
            if ! sudo apt-get install -y "$pkg"; then
                track_failure "apt" "Failed to install: $pkg"
            fi
        else
            echo "$pkg is already installed."
        fi
    done

    if ! grep -q "deadsnakes/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "Adding deadsnakes PPA for Python versions..."
        if ! sudo add-apt-repository ppa:deadsnakes/ppa -y; then
            track_failure "apt" "Failed to add deadsnakes PPA"
        fi
    else
        echo "deadsnakes PPA already added."
    fi

    if ! dpkg -s python3.10 &> /dev/null; then
        echo "Installing Python 3.10..."
        if ! sudo apt-get install -y python3.10 python3.10-venv; then
            track_failure "python" "Failed to install Python 3.10"
        fi
    else
        echo "Python 3.10 is already installed."
    fi
}

clean_unneeded_software() {
    echo "Cleaning up unneeded software..."
    sudo apt autoremove -y || track_failure "apt" "Failed to autoremove packages"
}

install_docker() {
    if [[ "${CODESPACES:-}" == "true" || -n "${CODESPACE_NAME:-}" || "$PWD" == /workspaces/* ]]; then
        echo "Skipping Docker install — running inside a Codespace (already provides docker)."
        return 0
    fi

    local docker_present=0
    if command -v docker >/dev/null 2>&1; then
        docker_present=1
        echo "docker CLI already present — skipping package install, ensuring config only."
    fi

    . /etc/os-release

    if (( ! docker_present )); then
        echo "Installing Docker CE for ${ID} ${VERSION_CODENAME}..."

        if ! sudo apt-get install -y -qq ca-certificates curl; then
            track_failure "docker" "Failed to install prerequisites (ca-certificates, curl)"
            return 1
        fi

    if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
        sudo install -m 0755 -d /etc/apt/keyrings
        if ! sudo curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc; then
            track_failure "docker" "Failed to fetch Docker GPG key"
            return 1
        fi
        sudo chmod a+r /etc/apt/keyrings/docker.asc
    fi

    if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
            | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi

    if ! sudo apt-get update -qq; then
        track_failure "docker" "Failed to apt-update after adding Docker repo"
        return 1
    fi

    if ! sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        track_failure "docker" "Failed to install docker-ce + plugins"
        return 1
    fi
    fi  # end: ! docker_present

    if ! getent group docker >/dev/null 2>&1; then
        sudo groupadd docker || track_failure "docker" "Failed to create docker group"
    fi

    if ! id -nG "$USER" | tr ' ' '\n' | grep -q '^docker$'; then
        echo "Adding $USER to the docker group..."
        if ! sudo usermod -aG docker "$USER"; then
            track_failure "docker" "Failed to add $USER to docker group"
        fi
    fi

    if command -v systemctl >/dev/null 2>&1 && [[ "$(ps -p 1 -o comm=)" == "systemd" ]]; then
        if ! sudo systemctl enable --now docker; then
            track_failure "docker" "Failed to enable/start docker service"
        fi
    else
        echo "Note: systemd not detected — start docker manually with: sudo service docker start"
    fi

    echo "Docker installed. Run 'newgrp docker' or open a new shell to use it without sudo."
    sudo docker version --format 'Client: {{.Client.Version}} | Server: {{.Server.Version}}' || true
}

setup_ubuntu() {
    update_system
    install_common_packages
    ensure_tmux_version
    install_neovim
    install_fzf
    install_ubuntu_specific_packages

    if [[ $CODESPACES != "true" ]]; then
        install_nvm
    fi
    install_lazygit
    install_claude_code
    install_playwright
    setup_python
    setup_symlinks
}

setup_codespace() {
    update_system
    install_common_packages
    ensure_tmux_version
    install_neovim
    install_fzf
    install_claude_code
    setup_python
    setup_symlinks
}
