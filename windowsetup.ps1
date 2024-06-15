#set up the bare repository on windows
#checkout the repository
Set-ExecutionPolicy RemoteSigned -Scope CurrentUse
irm get.scoop.sh | iex

scoop install neovim
scoop bucket add main
scoop install ripgrep
scoop install fzf
scoop bucket add nerd-fonts
scoop install FiraCode-NF

scoop install gcc
scoop bucket add versions
scoop install python310
pip install pynvim
scoop install fd
scoop install Cascadia-Code
scoop install nodejs
scoop install starship

git clone --force https://github.com/eduuh/nvim C:\Users\edwinmuraya\AppData\Local\.config\nvim
