Set-PSReadlineOption -EditMode vi -BellStyle None

function dotfiles() {
  git --git-dir=$HOME/.dotfiles --work-tree=$HOME $args
}

function setgit() {
   git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
}

function notes() {
  Set-Location "C:\Users\edwinmuraya\OneDrive - Microsoft\Notes"
  lvim
}

function config() {
  Set-Location  "C:\Users\edwinmuraya\AppData\Local\nvim"
}

function middleTier() {
  Set-Location "C:\Users\edwinmuraya\project\BingAtWork\services\DynamicSearchBox\"
}

$env:XDG_CONFIG_HOME = "C:\Users\edwinmuraya\.config"

Invoke-Expression (&starship init powershell)

Set-Alias lvim 'C:\Users\edwinmuraya\.local\bin\lvim.ps1'
