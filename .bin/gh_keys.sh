#!/bin/zsh
# GitHub SSH key setup script - Improved for seamless setup across platforms

# Set up error handling
set -e # Exit immediately if a command exits with a non-zero status
trap 'echo "Error: Command failed at line $LINENO. Exiting."; exit 1' ERR

# Print colorful status messages
print_status() {
  local COLOR="\033[1;34m" # Blue
  local RESET="\033[0m"
  echo "${COLOR}==>${RESET} $1"
}

print_success() {
  local COLOR="\033[1;32m" # Green
  local RESET="\033[0m"
  echo "${COLOR}==>${RESET} $1"
}

detect_os() {
  if [[ "$CODESPACES" == "true" ]]; then
    echo "codespace"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  elif [[ "$(uname)" == "Darwin" ]]; then
    echo "darwin"
  else
    echo "unknown"
  fi
}

install_dependencies() {
  local OS_TYPE=$(detect_os)
  print_status "Detected OS: $OS_TYPE"

  case "$OS_TYPE" in
    codespace|ubuntu|debian)
      install_for_ubuntu
      ;;
    arch)
      install_for_arch
      ;;
    darwin)
      install_for_macos
      ;;
    *)
      print_status "Unsupported operating system: $OS_TYPE. Will attempt to continue."
      ;;
  esac
}

install_for_ubuntu() {
  print_status "Installing dependencies for Ubuntu/Debian..."

  # Check if gh CLI is already installed
  if ! command -v gh &>/dev/null; then
    print_status "Installing GitHub CLI..."
    # Add GitHub CLI repository
    type -p curl >/dev/null || sudo apt-get install -y curl
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y gh
  else
    print_status "GitHub CLI already installed"
  fi

  # Install other dependencies if needed
  if ! command -v zsh &>/dev/null || ! command -v ssh &>/dev/null; then
    print_status "Installing additional dependencies..."
    sudo apt-get install -y zsh openssh-client
  fi
}

install_for_arch() {
  print_status "Installing dependencies for Arch Linux..."

  # Check if dependencies are already installed
  local packages_to_install=()

  if ! command -v gh &>/dev/null; then
    packages_to_install+=(github-cli)
  fi

  if ! command -v zsh &>/dev/null; then
    packages_to_install+=(zsh)
  fi

  if ! command -v ssh &>/dev/null; then
    packages_to_install+=(openssh)
  fi

  if [ ${#packages_to_install[@]} -gt 0 ]; then
    print_status "Installing: ${packages_to_install[*]}"
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm ${packages_to_install[*]}
  else
    print_status "All dependencies already installed"
  fi
}

install_for_macos() {
  print_status "Installing dependencies for macOS..."

  # Check if Homebrew is installed
  if ! command -v brew &>/dev/null; then
    print_status "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH if on Apple Silicon
    if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  # Check which packages need to be installed
  local packages_to_install=()

  if ! command -v gh &>/dev/null; then
    packages_to_install+=(gh)
  fi

  if ! command -v zsh &>/dev/null; then
    packages_to_install+=(zsh)
  fi

  if ! ssh -V &>/dev/null 2>&1; then
    packages_to_install+=(openssh)
  fi

  if [ ${#packages_to_install[@]} -gt 0 ]; then
    print_status "Installing: ${packages_to_install[*]}"
    brew update
    brew install ${packages_to_install[*]}
  else
    print_status "All dependencies already installed"
  fi
}

configure_ssh() {
  print_status "Setting up SSH key..."

  # Create .ssh directory if it doesn't exist
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  # Check if SSH key already exists
  if [ ! -f ~/.ssh/id_ed25519 ]; then
    print_status "Generating new ED25519 SSH key..."
    ssh-keygen -t ed25519 -C "31909722+eduuh@users.noreply.github.com" -f ~/.ssh/id_ed25519 -N ""
  else
    print_status "SSH key already exists"
  fi

  # Start ssh-agent and add key
  print_status "Starting ssh-agent..."
  eval "$(ssh-agent -s)"

  # Add SSH key to the agent
  print_status "Adding SSH key to ssh-agent..."
  ssh-add ~/.ssh/id_ed25519

  # Add SSH config if it doesn't exist
  if [ ! -f ~/.ssh/config ]; then
    print_status "Creating SSH config file..."

    # Use different configs for macOS vs Linux
    if [[ "$(uname)" == "Darwin" ]]; then
      cat > ~/.ssh/config << EOF
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
    else
      cat > ~/.ssh/config << EOF
Host github.com
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
EOF
    fi

    chmod 600 ~/.ssh/config
  fi
}

setup_github() {
  print_status "Setting up GitHub authentication..."

  # Check if already authenticated with GitHub
  if ! gh auth status &>/dev/null; then
    print_status "Authenticating with GitHub..."

    # GitHub authentication method
    gh auth login --web
  else
    print_status "Already authenticated with GitHub"
  fi

  # Add SSH key to GitHub account
  print_status "Adding SSH key to GitHub account..."
  gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname) $(date +'%Y-%m-%d')"
}

# Main script execution
main() {
  print_status "Starting GitHub SSH setup script..."

  install_dependencies
  configure_ssh
  setup_github

  print_success "✅ GitHub SSH key setup completed successfully!"
  print_success "✅ You can now clone repositories using SSH"
}

main
