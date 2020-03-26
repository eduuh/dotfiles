" Author: @edwinmuraya
" set clipboard=unamedplus
" ====
" ==== Editor behaviour
" ====

set number
set relativenumber
set cursorline
set noexpandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set scrolloff=4
set ttimeoutlen=0
set notimeout
set wrap
set foldmethod=indent
set foldlevel=99
set foldenable
set splitright
set splitbelow
set noshowmode
set showcmd
set wildmenu

set ignorecase
set smartcase
set visualbell
set colorcolumn=80
set updatetime=1000
set virtualedit=block

" ----
" ---- Basic mappings
" ----
" set <LEADER> as <SPACE>, ; as :
let mapleader=" "
noremap ; :

"save and quit"
noremap Q :q<CR>
noremap <C-q> :qa<CR>
noremap S :w<CR>

" Open the vimrc file anytime
noremap <LEADER>rc :e ~/.config/nvim/init.vim<CR>

" == Cursor Movement
" ==
" New cursor movement (the default arrow keys are used for resizing windows)
"          ^
"          u
"     <n       i>
"          e
"          v
noremap  <silent> u k
noremap  <silent> n h
noremap  <silent> e j
noremap  <silent> i l

" U/E keys for 5 times u/e (faster navigation)
noremap <silent> U 5K
noremap <silent> E 5j

" l key: go to the start of the line
noremap <silent> l 0
noremap <silent> I $

" Faster in-line navigation
noremap W 5w
noremap B 5b

" set h (same as n, cursor left) to 'end of word'
noremap h e

" Ctrl + U will move up / down the view port without moving the cursor

noremap <C-U> 5<C-y>
noremap <C-E> 5<c-e>

" ===
" === Insert Mode cursor Movement
" ===
inoremap <C-a> <ESC>A

" === Command Mode cursor Movement
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <c-p> <Up>
cnoremap <c-n> <Down>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <M-b> <S-Left>
cnoremap <M-w> <S-Right>

" === 
" Window Management
" ===
" Use <space> + new arrow keys for moving the cursor around windows.

noremap <LEADER>w <C-w>w
noremap <LEADER>u <C-w>k
noremap <LEADER>e <C-w>j
noremap <LEADER>n  <C-w>h
noremap <LEADER>i  <C-w>l

" disable the default s key
noremap s <nop>

" Insert key 
noremap k i
noremap K I
noremap ` ~

" make Y to copy till the end of the line
nnoremap Y y$

" Copy to system clipboard
vnoremap Y 

" Indentation
nnoremap < <<
nnoremap > >>

noremap <C-c> zz

" ===
" === Install plugins with Vim-plug
" ===
call plug#begin('~/.config/nvim/plugged')

" file navigation
Plug 'junegunn/fzf.vim'
" Auto complete
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" csharp
Plug 'OmniSharp/omnisharp-vim'
Plug 'ctrlvim/ctrlp.vim' , {'for': ['cs', 'vim-plug'] } 

" Html , CSS , Javascript, JSon
Plug 'elzr/vim-json'
Plug 'hail2u/vim-css3-syntax' , {'for' : ['vim-plug' , 'html' , 'javascript', 'css' , 'less' ] }

Plug 'pangloss/vim-javascript' , {'for': ['vim-plug', 'php','html','javascript' , 'css' , 'less'] }

" Markdown
Plug 'iamcco/markdown-preview.nvim', {'do': {-> mkdp#util#install_sync() }, 'for' : ['markdown', 'vim-plug']}
Plug 'dhruvasagar/vim-table-mode', {'on': 'TableModeToggle'}
Plug 'mzlogin/vim-markdown-toc', {'for':['gitignore','markdown']}

" Editor Enhancement
Plug 'jiangmiao/auto-pairs'
Plug 'mg979/vim-visual-multi'
Plug 'tpope/vim-surround'

call plug#end()
set lazyredraw



















