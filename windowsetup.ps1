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

# Lsp configurations helix setup
npm install --global prettier-eslint-cli
npm install --global  @typescript-eslint/eslint-plugin
npm install -g typescript typescript-language-server
npm i -g vscode-langservers-extracted
npm install --save-dev prettier prettier-plugin-solidity

git clone --force https://github.com/eduuh/Nvim_config C:\Users\edwinmuraya\AppData\Local\.config\nvim
