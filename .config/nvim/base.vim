
" Leader Shortcuts {{{
let mapleader="\<space>"
" }}}
" Spaces & Tabs {{{
set tabstop=2     " number of visual spaces per TAB
set softtabstop=2 " number of spaces in tab when editing
set expandtab     " turns <TAB's> into spaces.
set shiftwidth=2
set autoindent
set smartindent
set conceallevel=2
set mouse=a
" change directory to the current buffer when opening files.
" set autochdir

" }}}
" UI Layout {{{
" set number
" set relativenumber
set shortmess+=I         "hide splash screen 
set updatetime=100       "Reduce swap-writing update time (better for vim-gutter) 
" set cursorline    " highlight the current line
set nocursorline
set splitright | set splitbelow
set ruler         " show the cursor position all the time
set wildmenu  " Show a menu when using Tab completion
set wildmode=longest,full            " Tab complete longest common string, then each full match.
set showcmd
set scrolloff=5 "Show some few more line when using z-enter"
" }}}

" Neovim Misc {{{
scriptencoding utf-8
set encoding=utf-8
set visualbell    " stop that ANNOYING beeping
set autowrite     " Automatically :write before running commands
set autoread      " Reload files changed outside vim
set autowriteall  " save the buffer content fhe some specific commands are executed"
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif


" Searching {{{
set hlsearch      " Stop highlight after searching
" set gdefault      " Substitute all matches in a line (i.e. :s///g) by default
set nohlsearch
set ignorecase
set smartcase
set incsearch  "Highlig the search scheme when typing
set lbr


" Folding {{{
set wrapmargin=0
set nofoldenable
set foldmethod=manual
" }}}
set noshowmode


" colors  {{{
syntax on          " enables syntax procesing
set termguicolors
set termencoding=utf-8

set backspace=2   " Backspace deletes like most programs in insert mode
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287


filetype plugin indent on
"nnoremap <leader>w :write<Enter>
nnoremap <leader>s :setlocal spell!<cr>
nnoremap <leader>q :q<cr>
tmap <leader>q <C-d>
nnoremap <leader>t :split term://bash<CR>

autocmd BufWritePre markdown %s/\s\+$//e  " automatically remove all trailling whitespaces(allfiles).

"Reference for later usage.
" autocmd BufWritePost ~/media/data/dm/dwmblocks/config.h !cd ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid dwmblocks & }

augroup terminal_settings
autocmd!
autocmd BufWinEnter,WinEnter term://* startinsert
autocmd BufLeave term://* stopinsert
" Ignore various filetypes as those will close terminal automatically
" Ignore fzf, ranger, coc
autocmd TermClose term://*
  \ if (expand('<afile>') !~ "fzf") && (expand('<afile>') !~ "ranger") && (expand('<afile>') !~ "coc") |
  \   call nvim_input('<CR>')  |
  \ endif
augroup END
