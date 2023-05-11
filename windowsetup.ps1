#set up the bare repository on windows
#checkout the repository
git clone --bare https://github.com/eduuh/windows.dotfiles "$HOME/.dotfiles"
dotfiles config --local status.showUntrackedFiles no

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

# Lsp configurations setup
npm install --global prettier-eslint-cli
npm install --global  @typescript-eslint/eslint-plugin
npm install -g typescript typescript-language-server
npm i -g vscode-langservers-extracted
npm install --save-dev prettier prettier-plugin-solidity


rm -r C:\Users\edwinmuraya\AppData\Local\
cp -r .config\nvim  C:\Users\edwinmuraya\AppData\Local\

# refer here https://github.com/ChristianChiarulli/nvim/blob/master/lua/user/lsp/settings/tsserver.lua
