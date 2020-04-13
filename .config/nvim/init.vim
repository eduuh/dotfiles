" Initialzation
set nocompatible
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/plugged')

Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
" Plug 'sonph/onehalf', { 'rtp': 'vim/' }
Plug 'morhetz/gruvbox'
Plug 'tpope/vim-commentary'
Plug 'sheerun/vim-polyglot'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
Plug 'jparise/vim-graphql'
" post install (yarn install | npm install) then load plugin only for editing
" supported files
Plug 'prettier/vim-prettier', {'do': 'yarn install','for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }
call plug#end()

" Basicnn
set mouse:a noswf nu rnu ls=0 shm=aIFWc tgc ts=2 sw=2 sts=2 et nofen fenc=utf-8 cb+=unnamedplus ut=300
set wig+=*/.git,*/node_modules,*/venv,*/tmp,*.so,*.swp,*.zip,*.pyc,.DS_Store
set list lcs=tab:··,trail:·


" neiksj
 noremap n j
 noremap i l
 noremap e k
 noremap k n|noremap K N
 noremap s i
 noremap j e|noremap J E 
 " The best!
 noremap ; :|noremap : ;
 " _r_ = inner Text object
 onoremap r i
" Same redo.
noremap U <C-r>
" Auto-bracket
inoremap {<CR> {<CR>}<Esc>0


" Bold and italic in tmux
set t_ZH=[3m
set t_ZR=[23m

" Italic comments
hi Comment cterm=italic gui=italic

" Leader
let g:mapleader = ','


" Language tweaks
let g:javascript_plugin_jsdoc = 1
let g:vim_jsx_pretty_colorful_config = 1
let g:markdown_enable_conceal = 1

" minmal and better fzf layout
let $FZF_DEFAULT_OPTS .= ' --layout=reverse'
autocmd! FileType fzf set nosmd nonu nornu | autocmd BufLeave <buffer> set smd nu rnu

" ripgrep integration
function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang Rg call RipgrepFzf(<q-args>, <bang>0)

" reload vim-colemak to remap any overridden keys
" silent! source "$HOME/.vim/bundle/vim-colemak/plugin/colemak.vim"
" Fix for colemak.vim keymap collision. tpope/vim-fugitive's maps y<C-G>
" " and colemak.vim maps 'y' to 'w' (word). In combination this stalls 'y'
" " because Vim must wait to see if the user wants to press <C-G> as well.
 augroup RemoveFugitiveMappingForColemak
    autocmd!
        autocmd BufEnter * silent! execute "nunmap <buffer> <silent> y<C-G>"
 augroup END


 noremap <Up> <Nop>
 noremap <Down> <Nop>
 noremap <Left> <Nop>
 noremap <Right> <Nop>

 " pannes should split to the right, or to the bottom
 set splitbelow
 set splitright
" md means markdown
 autocmd BufNewFile,BufReadPost *.md set filetype=markdown

 " Vim Display 
 set t_Co=256             " 256 Colors.
 set shortmess+=I         " Hide splash screen.
 set display+=lastline    " Show partial lines.
 set showtabline=1        " show tabs only when multiple tabs are openet
 set laststatus=2         " Always show status bar.

 syntax on                " Syntax highlighting.
 set hlsearch             " Search highlighting.
 set wrap                 " Wrapping on.
 set lbr                  " Wrap at word.
 set expandtab            " Use spaces.


 " Editing
 set autoindent           " keep line indentation.
 set nowrapscan           " Don't wrap search to beginning of files.
 set incsearch            " Icremental searching.
 set ignorecase|set smartcase  " Ignore case when only lowercas letter are used.
 set gdefault                  " Substitute all matches in a line.
 set showmatch                 " When a bracket is insert at flash
 set confirm                   " Confirm quits/save/etc
 set background=dark
 " colorscheme onehalfdark
colorscheme gruvbox
