"|  \/  \ \ / / | \ | \ \   / /_ _|  \/  |  _ \ / ___|
"| |  | | | |   | |\  | \ V /  | || |  | |  _ <| |___
"|_|  |_| |_|   |_| \_|  \_/  |___|_|  |_|_| \_\\____|
" Author: @edwinmuraya
" Vim Plug {{{
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/plugged')
" Provides asynchronous execution.
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
"Plug 'fcpg/vim-fahrenheit'
Plug 'mattn/emmet-vim'
"intergrate fzf with vim {{{ fuzzy finding of files" Layout Look n Feal {{{
" Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
Plug 'dikiaap/minimalist' "The neovim color theme.
Plug 'tpope/vim-dadbod'
Plug 'itchyny/lightline.vim' " A light and configurable statusline/tabline plugin for Vim
Plug 'mhinz/vim-signify' " Show a diff using Vim's sign column.
Plug 'sonph/onehalf', { 'rtp': 'vim/' }
Plug 'tsiemens/vim-aftercolors' " Support for after/colors/ scripts
Plug 'christoomey/vim-tmux-navigator'
Plug 'djoshea/vim-autoread'

if has('nvim')
    Plug 'Shougo/defx.nvim', { 'do': ':UpdateRemotePlugins' }
  else
    Plug 'Shougo/defx.nvim'
    Plug 'roxma/nvim-yarp'
    Plug 'roxma/vim-hug-neovim-rpc'
  endif

Plug 'kristijanhusak/defx-git' " Git status column for defx
"}}}
" Git {{{
Plug 'tpope/vim-fugitive'
" Plug 'airblade/vim-gitgutter'
" }}}
" Markdown Support{{{
" Track the engine
Plug 'SirVer/ultisnips' 
Plug 'honza/vim-snippets'
" tabular plugin is used to format tables
Plug 'godlygeek/tabular'
" JSON front matter highlight plugin
Plug 'elzr/vim-json'
Plug 'plasticboy/vim-markdown'
" Markdown Previewing
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }}
" }}}

" Plugin --Editing {{{
" Plug 'tpope/vim-abolish' " easily search for, substitute, & abbreviate multiple variants of a word
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
"}}}
" Syntax highlingt for most languages {{{
Plug 'sheerun/vim-polyglot'
" }}}
" Javascript snippets
Plug 'pangloss/vim-javascript' " JS syntax highlighting and indentation
Plug 'leafgarland/typescript-vim' " TS syntax highlighting
Plug 'maxmellon/vim-jsx-pretty' " JSX and TSX syntax highlighting
Plug 'prettier/vim-prettier', { 'do': 'npm install' } " JS/TS/CSS/HTML Opinionated code formatter
Plug 'epilande/vim-es2015-snippets'
Plug 'epilande/vim-react-snippets'
" Conquer of Completion {{{
"}}}
Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release' }
let g:coc_global_extensions=['coc-eslint', 'coc-json', 'coc-tsserver', 'coc-html' , 'coc-css' , 'coc-pairs' , 'coc-jest', 'coc-snippets', 'coc-prettier']

"C# Configurations {{{
" Plug 'OmniSharp/omnisharp-vim'
"}}}
"}}}
"Latex {{{
" A Vim Plugin for Lively Previewing LaTeX PDF Output
" Plug 'xuhdev/vim-latex-live-preview', { 'for': 'tex' }
"}}}
"  Nerdtree {{{
" Plug 'preservim/nerdtree' " file tree
" Plug 'Xuyuanp/nerdtree-git-plugin'
"}}}
call plug#end()
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
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif
" }}}

" Searching {{{
set hlsearch      " Stop highlight after searching
" set gdefault      " Substitute all matches in a line (i.e. :s///g) by default
set nohlsearch
set ignorecase
set smartcase
set incsearch  "Highlig the search scheme when typing
set lbr

" }}}

" Colemak Remaps {{{
noremap n j
noremap i l
noremap e k
noremap k n
noremap K N
" _r_   inner Text object
noremap l i
noremap L I

" set j (same as h , cursor left) to 'end of word'
noremap j e
noremap J E

noremap ; :
noremap : ;

noremap <silent> H 0
noremap <silent> I $
noremap S :%s//g<left><left>
noremap U <C-r>

" Faster in-line navigation
nmap ,, <C-^>
cmap w!! w !sudo tee %
" Remapping for Ale {{{
nmap <silent> [c <Plug>(ale_previous_wrap)
nmap <silent> ]c <Plug>(ale_next_wrap)

" netrw browser images.
"noremap <silent> <C-b> :edit .<CR> 
"}}}
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
command! C execute ":e ~/.config/nvim/init.vim"
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
 " ctags optimization
" au FileType gitcommit,gitrebase,tags,md,yml,yaml,json,map
let g:gutentags_enabled=0


" Trigger autoread when changing buffers or coming back to vim in terminal.
au FocusGained,BufEnter * :silent! !
set backspace=2   " Backspace deletes like most programs in insert mode
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287

" Leader Shortcuts {{{
let mapleader="\<space>"
let g:user_emmet_leader_key=','
" save files in the buffer
nnoremap <leader>w :write<Enter>
nnoremap <leader>s :setlocal spell!<Enter>
nnoremap <leader>q :q<Enter>
tmap <leader>q <C-d>
nnoremap <leader>t :split term://zsh<CR>
" Use D to show documentation in preview window
nnoremap <silent> <leader>D :call <SID>show_documentation()<CR>
nnoremap <silent> <C-m> :MarkdownPreview<CR>
" nnoremap <leader>sp :normal! mz[s1z=`z<CR>
" Nerdtree Leader keymap's{{{
" nnoremap <silent> <leader>n :NERDTreeToggle<Enter>
" nnoremap <silent> <leader>v :NERDTreeFind<Enter>
" nnoremap <silent> <leader>gg :let g:gitgutter_enabled = 1<Enter> " has a conflict 

nnoremap <leader>d :CocList diagnostics<Enter>
noremap <leader>l :CocList<Enter>
" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references) 
  " Remap for rename current word
nmap re <Plug>(coc-rename)
  " Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
  " Fix autofix problem of current line
nmap <leader>af  <Plug>(coc-fix-current)

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" }}}
" }}}
" Emmet{{{
" redefine trigger key
" }}}
" Functions {{{
function! s:show_documentation()
    if (index(['vim','help'], &filetype) >= 0)
      execute 'h '.expand('<cword>')
    else
      call CocAction('doHover')
    endif
  endfunction

" }}}
" AutoGroups {{{
  " restricting to some file use c,cpp,java instead of *
autocmd BufWritePre markdown %s/\s\+$//e  " automatically remove all trailling whitespaces(allfiles).
autocmd FileType gitcommit setlocal textwidth=100 " Automatically wrap at 100 characters.

autocmd BufWritePost ~/.local/src/dwmblocks/config.h !cd ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid dwmblocks & }
" open file, but keep focus in Exproler.
"autocmd FileType netrw nmap <C-a> <cr>:wincmd W<cr>
" autocmd FileType gitcommit setlocal spell " automaticall spell check commits
" autocmd FileType markdown setlocal spell " spell check markdown files
  augroup mygroup
    autocmd!
    " Setup formatexpr specified filetype(s).
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
    " Update signature help on jump placeholder
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  augroup END

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


" }}}
filetype plugin indent on
"Markdown {{{
let g:UltiSnipsExpandTrigger="<c-l>"  " use <Tab> to trigger autocompletion
let g:UltiSnipsJumpForwardTrigger="<c->"
let g:UltiSnipsJumpBackwardTrigger="<c-e>"
" disable header folding
let g:vim_markdown_folding_disabled = 1

" do not use conceal feature, the implementation is not so good
let g:vim_markdown_conceal = 0

" disable math tex conceal feature
let g:tex_conceal = ""
let g:vim_markdown_math = 1

" support front matter of various format
let g:vim_markdown_frontmatter = 1  " for YAML format
let g:vim_markdown_toml_frontmatter = 1  " for TOML format
let g:vim_markdown_json_frontmatter = 1  " for JSON format
" Markdown Previewing {{{
" do not close the preview tab when switching to other buffers
let g:mkdp_auto_close = 0
"}}} 
augroup pandoc_syntax
    au! BufNewFile,BufFilePre,BufRead *.md set filetype=markdown.pandoc
augroup END
" }}}


" Fzf_Layout {{{ avoiding files from openning in neardtree config
au BufEnter * if bufname('#') =~ 'NERD_tree' && bufname('%') !~ 'NERD_tree' && winnr('$') > 1 | b# | exe "normal! \<c-w>\<c-w>" | :blast | endif
" }}}
"Vim-gitgutter {{{
" let g:gitgutter_enabled = 1
"}}}

"Ale settings {{{
let g:ale_linter_aliases = {'js': ['jsx',  'typescript', 'tsx', 'vue', 'javascript'], 'cs': ['OminiSharp']}
let g:ale_linters = {
        \ '*': ['remove_trailing_lines', 'trim_whitespace'], 'js': ['eslint', 'prettier'],
        \  'haskell': ['stack-ghc-mod', 'hlint']
        \ }

let g:ale_fixers = { 'javascript': ['prettier', 'eslint'] }
let g:ale_fix_on_save = 1
"}}}

"ominisharp {{{
"let g:OmniSharp_selector_ui = 'fzf'    " Use fzf.vim
"}}}

" Coc Configuration {{{
let g:coc_snippet_next = '<TAB>'
let g:coc_snippet_prev = '<S-TAB>'
" let g:coc_status_error_sign = '•'
" let g:coc_status_warning_sign = '••'
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

"Defx  {{{
nnoremap <silent> <Leader><leader> :Defx<CR>

  call defx#custom#option('_', {
      \ 'columns': 'git:indent:icon:filename',
      \ 'winwidth':30,
      \ 'split': 'vertical',
      \ 'direction': 'topleft',
      \ 'show_ignored_files': 0,
      \ 'buffer_name': '',
      \ 'toggle': 1,
      \ 'resume': 1,
      \ 'root_marker': '‣‣‣ ',
      \ })
  call defx#custom#column('indent', { 'indent': '  ' })
  call defx#custom#column('git', 'indicators', {
      \ 'Modified'  : '‣',
      \ 'Staged'    : '✚',
      \ 'Untracked' : '✭',
      \ 'Renamed'   : '➜',
      \ 'Unmerged'  : '═',
      \ 'Ignored'   : '☒',
      \ 'Deleted'   : '✖',
      \ 'Unknown'   : '?',
      \ })

" Quit if defx is the last window.
autocmd WinEnter * if &ft == 'defx' && winnr('$') == 1 | q | endif

  " defx mappings.
autocmd FileType defx call s:defx_my_settings()
	function! s:defx_my_settings() abort
	  " Define mappings
    nnoremap <silent><buffer><expr> <CR> defx#is_directory() ? defx#do_action('open_or_close_tree') : defx#do_action('open', 'wincmd p \| drop')
    nnoremap <silent><buffer><expr> o defx#is_directory() ? defx#do_action('open_or_close_tree') : defx#do_action('open', 'wincmd p \| drop')
	  nnoremap <silent><buffer><expr> s defx#do_action('open', 'wincmd p \| split')
	  nnoremap <silent><buffer><expr> v defx#do_action('open', 'wincmd p \| vsplit')
	  nnoremap <silent><buffer><expr> t defx#do_action('open', 'tabnew')
	  nnoremap <silent><buffer><expr> O defx#do_action('open_tree_recursive')
	  nnoremap <silent><buffer><expr> x defx#do_action('close_tree')
	  " nnoremap <silent><buffer><expr> go defx#do_action('open', 'pedit')
    nnoremap <silent><buffer><expr> C defx#do_action('cd', defx#get_candidate().action__path)
	  nnoremap <silent><buffer><expr> u defx#do_action('cd', '..')

	  nnoremap <silent><buffer><expr> a defx#do_action('new_file')
	  nnoremap <silent><buffer><expr> A defx#do_action('new_multiple_files')
	  nnoremap <silent><buffer><expr> c defx#do_action('copy')
	  nnoremap <silent><buffer><expr> p defx#do_action('paste')
	  nnoremap <silent><buffer><expr> m defx#do_action('move')
	  nnoremap <silent><buffer><expr> r defx#do_action('rename')
	  nnoremap <silent><buffer><expr> dd defx#do_action('remove')

	  nnoremap <silent><buffer><expr> yy defx#do_action('yank_path')

	  nnoremap <silent><buffer><expr> H defx#do_action('toggle_ignored_files')
	  nnoremap <silent><buffer><expr> R defx#do_action('redraw')
	  " nnoremap <silent><buffer><expr> u defx#do_action('cd', ['..'])
	  nnoremap <silent><buffer><expr> q defx#do_action('quit')
	endfunction
"}}} 
"
" LightLine {{{
 " Hide ex-line mode since it's displayed in lightline.
  set noshowmode
  let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ }
  let g:lightline.component_function = {
        \ 'filename': 'LightlineFilename'
      \ }
  let g:lightline.active = {
        \ 'left': [ ['mode'], ['filename', 'readonly', 'modified'] ],
        \ 'right': [ ['lineinfo'], ['percent'] ],
      \ }
	let g:lightline.inactive = {
        \ 'left': [ ['filename', 'readonly', 'modified'] ],
        \ 'right': [ ['lineinfo'], [ 'percent'] ],
      \ }
	let g:lightline.tabline = {
        \ 'left': [ ['tabs'] ],
        \ 'right': [ ],
      \ }

  " A custom Lightline filename that includes the file's parent directory.
  function! LightlineFilename()
      return expand('%:p:h:t') . '/' . expand('%:t')
  endfunction
" }}}

"Prettier {{{
let g:prettier#autoformat = 0
autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx,*.json,*.yaml,*.scss,*.css,*.less PrettierAsync


" signify {{{
let g:signify_vcs_list = ['git']
  " No realtime. Signify auto-saves modified buffers with realtime enabled. wtf.
let g:signify_realtime = 0

let g:signify_sign_add = '+'
let g:signify_sign_change = '~'
let g:signify_sign_delete = '_'
let g:signify_sign_delete_first_line = '‾'
" }}}

"Fzf {{{
" FZF commands
let g:fzf_command_prefix = 'Fzf'
nnoremap <silent> <Leader>a :FzfAg<cr>
nnoremap <silent> <Leader>f :FzfFiles<cr>
nnoremap <silent> <Leader>o :All<cr>
nnoremap <silent> <Leader>h :FzfHelptags<cr>
nnoremap <silent> <Leader>/ :FzfBLines<cr>
nnoremap <silent> <Leader>h :FzfHistory:<cr>
nnoremap <silent> <Leader>; :FzfHistory:<cr>
nnoremap <silent> <leader>b :FzfBuffers<cr>
  " Extra key bindings
  " <C-n> (down), <C-e> (up), etc are mapped via $FZF_DEFAULT_OPTS.
let g:fzf_action = {
  \ 'ctrl-h': 'topleft vsplit',
  \ 'ctrl-i': 'botright vsplit',
  \ 'H': 'aboveleft vsplit',
  \ 'N': 'belowright split',
  \ 'E': 'aboveleft split',
  \ 'I': 'belowright vsplit',
  \ 'T': 'tab split',
  \ }
  " Open FZF in tmux at bottom of screen.
let g:fzf_layout = { 'down': '~40%' }
  " Disable statusline overwriting.
let g:fzf_nvim_statusline = 0
  " [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

  " Hide the statusbar in the FZF pane.
  augroup fzf
    autocmd!
    autocmd! FileType fzf
    autocmd  FileType fzf set laststatus=0 noshowmode noruler
        \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler
  augroup END

command! -bang -nargs=*  All
  \ call fzf#run(fzf#wrap({'source': 'rg --files --hidden --no-ignore-vcs --glob "!{node_modules/*,.git/*}"', 'down': '40%', 'options': '--expect=ctrl-t,ctrl-x,ctrl-v --multi --reverse' }))
"}}}


" don't allow colorschemes to set a background color
highlight Normal ctermbg=NONE
highlight nonText ctermbg=NONE

" colors  {{{
syntax on          " enables syntax procesing
set background=dark
colo minimalist
set termguicolors
set termencoding=utf-8
