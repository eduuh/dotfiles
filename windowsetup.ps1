# Set the script execution policy for the current user
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install Scoop (a command-line installer for Windows)
Write-Host "Installing Scoop..."
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    irm get.scoop.sh | iex
} else {
    Write-Host "Scoop is already installed."
}

# Function to install Scoop apps if not already installed
function Install-ScoopApp {
    param (
        [string]$appName,
        [string]$bucket = $null
    )
    if ($bucket) {
        scoop bucket add $bucket -ErrorAction SilentlyContinue
    }
    if (-not (scoop which $appName)) {
        Write-Host "Installing $appName..."
        scoop install $appName
    } else {
        Write-Host "$appName is already installed."
    }
}

# Install essential tools and configurations
Install-ScoopApp -appName "neovim"
Install-ScoopApp -appName "ripgrep"
Install-ScoopApp -appName "fzf"
Install-ScoopApp -appName "gcc"
Install-ScoopApp -appName "fd"
Install-ScoopApp -appName "Cascadia-Code"
Install-ScoopApp -appName "nodejs"
Install-ScoopApp -appName "starship"
Install-ScoopApp -appName "git"
Install-ScoopApp -appName "powershell"

# Install specific tools from other Scoop buckets
Install-ScoopApp -appName "python3" -bucket "versions"

Install-ScoopApp -appName "nerd-fonts" -buckets "nerd-fonts/FiraCode-NF"

# Install Python package for Neovim
Write-Host "Installing pynvim..."
python.exe -m pip install --upgrade pip
pip install pynvim --user

foreach ($package in $npmPackages) {
    if (-not (npm list -g --depth=0 | Select-String -Pattern $package)) {
        Write-Host "Installing $package..."
        npm install --global $package
    } else {
        Write-Host "$package is already installed."
    }
}

Write-Host "Setup completed successfully!"
