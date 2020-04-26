" __  ____   __  _   ___     _____ __  __ ____   ____
"|  \/  \ \ / / | \ | \ \   / /_ _|  \/  |  _ \ / ___|
"| |\/| |\ V /  |  \| |\ \ / / | || |\/| | |_) | |
"| |  | | | |   | |\  | \ V /  | || |  | |  _ <| |___
"|_|  |_| |_|   |_| \_|  \_/  |___|_|  |_|_| \_\\____|

" Author: @edwinmuraya
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/plugged')

Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
" Plug 'sonph/onehalf', { 'rtp': 'vim/' }
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
" CSharp
Plug 'OmniSharp/omnisharp-vim'
Plug 'ctrlpvim/ctrlp.vim' , { 'for': ['cs', 'vim-plug'] } " omnisharp-vim dependency
" HTML, CSS, JavaScript, PHP, JSON, etc.
Plug 'elzr/vim-json'
Plug 'hail2u/vim-css3-syntax', { 'for': ['vim-plug', 'php', 'html', 'javascript', 'css', 'less'] }
Plug 'spf13/PIV', { 'for' :['php', 'vim-plug'] }
Plug 'pangloss/vim-javascript', { 'for': ['vim-plug', 'php', 'html', 'javascript', 'css', 'less'] }
Plug 'yuezk/vim-js', { 'for': ['vim-plug', 'php', 'html', 'javascript', 'css', 'less'] }
Plug 'MaxMEllon/vim-jsx-pretty', { 'for': ['vim-plug', 'php', 'html', 'javascript', 'css', 'less'] }
Plug 'jelera/vim-javascript-syntax', { 'for': ['vim-plug', 'php', 'html', 'javascript', 'css', 'less'] }
"Plug 'jaxbot/browserlink.vim'
" post install (yarn install | npm install) then load plugin only for editing
" supported files
Plug 'prettier/vim-prettier', {'do': 'yarn install','for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }
" Markdown
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install_sync() }, 'for' :['markdown', 'vim-plug'] }
Plug 'dhruvasagar/vim-table-mode', { 'on': 'TableModeToggle' }
Plug 'mzlogin/vim-markdown-toc', { 'for': ['gitignore', 'markdown'] }
Plug 'theniceboy/bullets.vim'
" Editor Enhancement
"Plug 'Raimondi/delimitMate'
Plug 'jiangmiao/auto-pairs'
Plug 'mg979/vim-visual-multi'
Plug 'scrooloose/nerdcommenter' " in <space>cn to comment a line
Plug 'AndrewRadev/switch.vim' " gs to switch
Plug 'tpope/vim-surround' " type yskw' to wrap the word with '' or type cs'` to change 'word' to `word`
Plug 'gcmt/wildfire.vim' " in Visual mode, type k' to select all text in '', or type k) k] k} kp
Plug 'junegunn/vim-after-object' " da= to delete what's after =
Plug 'junegunn/vim-easy-align' " gaip= to align the = in paragraph, 
Plug 'tpope/vim-capslock'	" Ctrl+L (insert) to toggle capslock
Plug 'easymotion/vim-easymotion'
Plug 'Konfekt/FastFold'
"Plug 'junegunn/vim-peekaboo'
"Plug 'wellle/context.vim'
Plug 'svermeulen/vim-subversive'
" Other useful utilities
Plug 'lambdalisue/suda.vim' " do stuff like :sudowrite
Plug 'makerj/vim-pdf'
"Plug 'xolox/vim-session'
"Plug 'xolox/vim-misc' " vim-session dep

"color schemes
Plug 'ajmwagar/vim-deus'
Plug 'morhetz/gruvbox'
call plug#end()

" initialization
set nocompatible
" Basicnn
set mouse:a noswf nu rnu ls=0 shm=aIFWc tgc ts=2 sw=2 sts=2 et nofen fenc=utf-8 cb+=unnamedplus ut=300
set wig+=*/.git,*/node_modules,*/venv,*/tmp,*.so,*.swp,*.zip,*.pyc,.DS_Store
set list lcs=tab:··,trail:·


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
" ===
" === MarkdownPreview
" ===
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 1
let g:mkdp_refresh_slow = 0
let g:mkdp_command_for_global = 0
let g:mkdp_open_to_the_world = 0
let g:mkdp_open_ip = ''
let g:mkdp_echo_preview_url = 0
let g:mkdp_browserfunc = ''
let g:mkdp_preview_options = {
			\ 'mkit': {},
			\ 'katex': {},
			\ 'uml': {},
			\ 'maid': {},
			\ 'disable_sync_scroll': 0,
			\ 'sync_scroll_type': 'middle',
			\ 'hide_yaml_meta': 1
			\ }
let g:mkdp_markdown_css = ''
let g:mkdp_highlight_css = ''
let g:mkdp_port = ''
let g:mkdp_page_title = '「${name}」'

" ===
" === OmniSharp
" ===
let g:OmniSharp_typeLookupInPreview = 1
let g:omnicomplete_fetch_full_documentation = 1
let g:OmniSharp_server_use_mono = 1
let g:OmniSharp_server_stdio = 1
let g:OmniSharp_highlight_types = 2
let g:OmniSharp_selector_ui = 'ctrlp'
autocmd Filetype cs nnoremap <buffer> gd :OmniSharpPreviewDefinition<CR>
autocmd Filetype cs nnoremap <buffer> gr :OmniSharpFindUsages<CR>
autocmd Filetype cs nnoremap <buffer> gy :OmniSharpTypeLookup<CR>
autocmd Filetype cs nnoremap <buffer> ga :OmniSharpGetCodeActions<CR>
autocmd Filetype cs nnoremap <buffer> <LEADER>rn :OmniSharpRename<CR><C-N>:res +5<CR>

sign define OmniSharpCodeActions text=💡
augroup OSCountCodeActions
	autocmd!
	autocmd FileType cs set signcolumn=yes
	autocmd CursorHold *.cs call OSCountCodeActions()
augroup END

function! OSCountCodeActions() abort
	if bufname('%') ==# '' || OmniSharp#FugitiveCheck() | return | endif
	if !OmniSharp#IsServerRunning() | return | endif
	let opts = {
				\ 'CallbackCount': function('s:CBReturnCount'),
				\ 'CallbackCleanup': {-> execute('sign unplace 99')}
				\}
	call OmniSharp#CountCodeActions(opts)
endfunction
function! s:CBReturnCount(count) abort
	if a:count
		let l = getpos('.')[1]
		let f = expand('%:p')
		execute ':sign place 99 line='.l.' name=OmniSharpCodeActions file='.f
	endif
endfunction

" ===
" === CTRLP (Dependency for omnisharp)
" ===
let g:ctrlp_map = ''
let g:ctrlp_cmd = 'CtrlP'

" ===
" === Markdown Settings
" ===
" Snippets
"source ~/.config/nvim/md-snippets.vim
" auto spell
autocmd BufRead,BufNewFile *.md setlocal spell

" disable the arrow keys
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
 " Dress up my vim
set termguicolors             "enable true colors support"
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set background=dark

" colemak remapping to neiksj
noremap n j
noremap i l
noremap e k
noremap k n|noremap K N
noremap l i
" set j (same as h , cursor left) to 'end of word'
noremap j e|noremap J E 
" The best!
noremap ; :|noremap : ;
noremap <silent> H 0
noremap <silent> I $
 
 " Faster in-line navigation
noremap W 5w
noremap B 5b

" _r_ = inner Text object
onoremap r i
" Same redo.
noremap U <C-r>
" Auto-bracket
inoremap {<CR> {<CR>}<Esc>0

" Ctrl + Y or E will move up/down the view port without moving the cursor 
noremap <C-y> 5<C-y> 
noremap <C-e> 5<C-e>

" Bold and italic inx
set t_ZH=[3m
set t_ZR=[23m
" Italic comments
hi Comment cterm=italic gui=italic

" Disable the default s key
"noremap s <non>
" split the screens to up (horizontal), down (horizontal), left (vertical), right (vertical)
noremap se :set nosplitbelow<CR>:split<CR>:set splitbelow<CR>
noremap sn :set splitbelow<CR>:split<CR>
noremap sh :set nosplitright<CR>:vsplit<CR>:set splitright<CR>
noremap si :set splitright<CR>:vsplit<CR>

"  Window management
" Use <spaace> + new arrow keys for moving the cursor around windows
" set clipboard=unamedplus
noremap <LEADER>w <C-w>w
noremap <LEADER>e <C-w>k
noremap  <LEADER>n <C-w>j
noremap  <LEADER>h <C-w>h
noremap   <LEADER>i <C-w>l
" Tab managements
" Create a new tab with tu
noremap tu :tabe<CR>
" Move around tabs with tn and ti
noremap tn :-tabnext<CR>
noremap ti :+tabnext<CR>
" Move the tabs with tmn and tmi
noremap tmn :-tabmove<CR>
noremap tmi :+tabmove<CR>
"Press <space> + q to close the window below the current window.

noremap <LEADER>q <C-w>j:q<CR>

set autochdir
set tabstop=2
set wrap
set visualbell
nnoremap < <<
nnoremap > >>
" === Necessary Commands to Execute
" ===
exec "nohlsearch"
" ===
" === Basic Mappings
" ===
" Set <LEADER> as <SPACE>, ; as :
let mapleader=" "

" folding
noremap <silent> <LEADER>o za

" Rotate screen
noremap srh <C-w>b<C-w>K
noremap srv <C-w>b<C-w>H

" Opening a terminal window
noremap <LEADER>/ :set splitbelow<CR>:split<CR>:res +10<CR>:term<CR>

"Spelling Check with <space>sc
noremap <LEADER>sc :set spell!<CR>

" find and replac
noremap \s :%s//g<left><left>
