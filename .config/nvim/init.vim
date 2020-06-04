" __  ____   __  _   ___     _____ __  __ ____   ____
"|  \/  \ \ / / | \ | \ \   / /_ _|  \/  |  _ \ / ___|
"| |\/| |\ V /  |  \| |\ \ / / | || |\/| | |_) | |
"| |  | | | |   | |\  | \ V /  | || |  | |  _ <| |___
"|_|  |_| |_|   |_| \_|  \_/  |___|_|  |_|_| \_\\____|
" Author: @edwinmuraya

" Spaces & Tabs {{{
set tabstop=4     " number of visual spaces per TAB
set softtabstop=4 " number of spaces in tab when editing
set expandtab     " turns <TAB's> into spaces.
set shiftwidth=2
set autoindent
set smartindent
" }}}

" UI Layout {{{
set number
set relativenumber
set nocursorline
set lazyredraw
set showmatch
set fillchars+=stl:\ ,stlnc:\
set splitright
set ruler         " show the cursor position all the time
" }}}

" Neovim Misc {{{
scriptencoding utf-8
set encoding=utf-8
set visualbell    " stop that ANNOYING beeping
set autowrite     " Automatically :write before running commands
set autoread      " Reload files changed outside vim

if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif
" }}}

" Searching {{{
set hlsearch      " Stop highlight after searching
set cursorline    " highlight the current line
set gdefault
set ignorecase
" }}}

" Colemak Remaps {{{
noremap n j
noremap i l
noremap e k
noremap k n
noremap K N
noremap l i
" set j (same as h , cursor left) to 'end of word'
noremap j e
noremap J E

noremap ; :
noremap : ;

noremap <silent> H 0
noremap <silent> I $
noremap S :%s//g<left><left>
noremap U <C-r>
onoremap r i
" _r_ = inner Text object

" Faster in-line navigation
nmap ,, <C-^>
cmap w!! w !sudo tee %
" }}}

" Folding {{{
set wrapmargin=0
" }}}
" Configure Cursor shape based on mode {{{
let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"
"}}}

" Commands {{{
command! Reload execute "source ~/.config/nvim/init.vim"
command! Config execute ":e ~/.config/nvim/init.vim"
" }}}
" Tab managements {{{
 " Create a new tab with tu
noremap tu :tabe<CR>
" Move around tabs with tn and ti
noremap tp :tabprev<Enter>
noremap tn :tabnext<Enter>
" Move the tabs with tmn and tmi
noremap tmp :-tabmove<CR>
noremap tmn :+tabmove<CR>
"Press <space> + q to close the window below the current window.
" }}}

set ttimeout
set ttimeoutlen=0
set formatoptions=qrn1
set cc=0
set exrc
set secure
set rtp+=/usr/local/lib/python2.7/site-packages/powerline/bindings/vim
 " ctags optimization
au FileType gitcommit,gitrebase,tags,md,yml,yaml,json,map
let g:gutentags_enabled=0


" Trigger autoread when changing buffers or coming back to vim in terminal.
au FocusGained,BufEnter * :silent! !
set backspace=2   " Backspace deletes like most programs in insert mode
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287

" Leader Shortcuts {{{
let mapleader="\<space>"
" save files in the buffer
nnoremap <leader>w :write<Enter>
nnoremap <leader>s :setlocal spell!<Enter>
" nnoremap <leader>sp :normal! mz[s1z=`z<CR>
" Nerdtree Leader keymap's{{{
nnoremap <silent> <leader>n :NERDTreeToggle<Enter>
nnoremap <silent> <leader>v :NERDTreeFind<Enter>
nnoremap <silent> <leader>gg :let g:gitgutter_enabled = 1<Enter>
nnoremap <silent> <leader>f :FZF<Enter>
nnoremap <silent> <leader>F : FZF ~<cr>
nnoremap <leader>d :CocList diagnostics<Enter>
noremap <leader>l :CocList<Enter>
" }}}
" }}}
" AutoGroups {{{
  " restricting to some file use c,cpp,java instead of *
autocmd BufWritePre * %s/\s\+$//e  " automatically remove all trailling whitespaces(allfiles).
autocmd FileType gitcommit setlocal textwidth=100 " Automatically wrap at 100 characters.
autocmd FileType gitcommit setlocal spell " automaticall spell check commits
autocmd FileType markdown setlocal spell " spell check markdown files
" }}}

" Vim Plug {{{
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/plugged')

" Layout Look n Feal {{{
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dikiaap/minimalist' "The neovim color theme.
"}}}
"  Nerdtree {{{
Plug 'preservim/nerdtree' " file tree
Plug 'Xuyuanp/nerdtree-git-plugin'
"}}}
" Git {{{
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
" }}}
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'chemzqm/vim-jsx-improve'
Plug 'dense-analysis/ale' " Linting
" Conquer of Completion {{{

"intergrate fzf with vim {{{
Plug 'junegunn/fzf.vim'
Plug '~/.fzf'
"}}}
Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release' }
let g:coc_global_extensions=['coc-json', 'coc-tsserver', 'coc-emmet', 'coc-html' , 'coc-css' , 'coc-pairs' , 'coc-jest', 'coc-prettier' , 'coc-eslint' , 'coc-snippets']

"}}}

call plug#end()
" }}}
" colors  {{{
syntax enable          " enables syntax procesing
colorscheme minimalist " color theme am Using
set background=dark
set termguicolors
set termencoding=utf-8
" }}}
" Nerdtree {{{
" Open nerdtree if no file is specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Close  vim it the only window left open is a NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" open nerdtree when you open a directory
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif
" nerdtree-git-plugins {{{
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ 'Ignored'   : '☒',
    \ "Unknown"   : "?"
    \ }
" }}}
let NERDTreeAutoDeleteBuffer = 1 " automaticall delete the buffer of the file
let g:NERDTreeIgnore = ['^\.DS_Store$', '^tags$', '\.git$[[dir]]', '\.idea$[[dir]]', '\.sass-cache$']
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
" let g:NERDTreeShowHidden = 1
" }}}
" Vim-Airline {{{
let g:airline_theme='minimalist'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#tabline#show_tabs = 0
" }}}

" Fzf_Layout {{{ avoiding files from openning in neardtree config
au BufEnter * if bufname('#') =~ 'NERD_tree' && bufname('%') !~ 'NERD_tree' && winnr('$') > 1 | b# | exe "normal! \<c-w>\<c-w>" | :blast | endif
" }}}
"Vim-gitgutter {{{
let g:gitgutter_enabled = 1
"}}}

"Ale settings {{{
let g:ale_linter_aliases = {'js': ['jsx',  'typescript', 'tsx', 'vue', 'javascript']}

let g:ale_linters = {
        \ '*': ['remove_trailing_lines', 'trim_whitespace'], 'js': ['eslint', 'prettier'],
        \  'haskell': ['stack-ghc-mod', 'hlint']
        \ }

let g:ale_fixers = { 'javascript': ['prettier'] }
"}}}

" Coc Configuration {{{
let g:coc_snippet_next = '<TAB>'
let g:coc_snippet_prev = '<S-TAB>'
let g:coc_status_error_sign = '•'
let g:coc_status_warning_sign = '••'
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif " close preview window when completion is done"
" }}}
