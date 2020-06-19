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
set conceallevel=2
" change directory to the current buffer when opening files.
set autochdir
" }}}

" UI Layout {{{
" set number
" set relativenumber
set nocursorline
set lazyredraw
set showmatch
set fillchars+=stl:\ ,stlnc:\
set splitright
set ruler         " show the cursor position all the time
filetype indent plugin on

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
" Remapping for Ale {{{
nmap <silent> [c <Plug>(ale_previous_wrap)
nmap <silent> ]c <Plug>(ale_next_wrap)

" netrw browser images.
noremap <silent> <C-b> :edit .<CR> 
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
 " ctags optimization
" au FileType gitcommit,gitrebase,tags,md,yml,yaml,json,map
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
" Use D to show documentation in preview window
nnoremap <silent> <leader> D :call <SID>show_documentation()<CR>
nnoremap <silent> <C-m> :MarkdownPreview<CR>
" nnoremap <leader>sp :normal! mz[s1z=`z<CR>
" Nerdtree Leader keymap's{{{
" nnoremap <silent> <leader>n :NERDTreeToggle<Enter>
" nnoremap <silent> <leader>v :NERDTreeFind<Enter>
" nnoremap <silent> <leader>gg :let g:gitgutter_enabled = 1<Enter> " has a conflict 
nnoremap <silent> f :FZF<Enter>
nnoremap <silent> F : FZF ~<cr>

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

nnoremap <leader>b :Buffers<Enter>
nnoremap <leader>h :History<Enter>
" }}}
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

" open file, but keep focus in Exproler.
autocmd FileType netrw nmap <C-a> <cr>:wincmd W<cr>
" autocmd FileType gitcommit setlocal spell " automaticall spell check commits
" autocmd FileType markdown setlocal spell " spell check markdown files
  augroup mygroup
    autocmd!
    " Setup formatexpr specified filetype(s).
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
    " Update signature help on jump placeholder
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
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
"Latex {{{
" A Vim Plugin for Lively Previewing LaTeX PDF Output
" Plug 'xuhdev/vim-latex-live-preview', { 'for': 'tex' }
"}}}
"  Nerdtree {{{
" Plug 'preservim/nerdtree' " file tree
" Plug 'Xuyuanp/nerdtree-git-plugin'
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

Plug 'vim-pandoc/vim-pandoc-syntax'
" }}}
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'chemzqm/vim-jsx-improve'

" Syntax highlingt for most languages {{{
Plug 'sheerun/vim-polyglot'
" }}}
" Javascript snippets
Plug 'dense-analysis/ale' " Linting
Plug 'yuezk/vim-js' " Linting
Plug 'maxmellon/vim-jsx-pretty' " Linting

" Conquer of Completion {{{
"intergrate fzf with vim {{{ fuzzy finding of files
Plug 'junegunn/fzf.vim'
Plug '~/.fzf'
"}}}
Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release' }
let g:coc_global_extensions=['coc-json', 'coc-tsserver', 'coc-emmet', 'coc-html' , 'coc-css' , 'coc-pairs' , 'coc-jest', 'coc-prettier' , 'coc-eslint' , 'coc-snippets']

"C# Configurations {{{
" Plug 'OmniSharp/omnisharp-vim'
"}}}
"}}}

call plug#end()
" }}}
" colors  {{{
syntax enable          " enables syntax procesing
colorscheme minimalist " color theme am Using
set background=dark
set termguicolors
set termencoding=utf-8
"Markdown {{{
let g:UltiSnipsExpandTrigger="<tab>"  " use <Tab> to trigger autocompletion
let g:UltiSnipsJumpForwardTrigger="<c-n>"
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

" Nerdtree {{{
" Open nerdtree if no file is specified
" autocmd StdinReadPre * let s:std_in=1
" autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" vim latex live preview settings plugin {{{
" autocmd Filetype tex setl updatetime=1
" let g:livepreview_previewer = 'open -a zathura'
" }}}
" Close  vim it the only window left open is a NERDTree
" autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" open nerdtree when you open a directory
"autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif
" nerdtree-git-plugins {{{
" }}}
"let NERDTreeAutoDeleteBuffer = 1 " automaticall delete the buffer of the file

" let g:NERDTreeIgnore = ['^\.DS_Store$', '^tags$', '\.git$[[dir]]', '\.idea$[[dir]]', '\.sass-cache$']
"let NERDTreeMinimalUI = 1
"let NERDTreeDirArrows = 1
" let g:NERDTreeShowHidden = 1
" }}}
" Netrw {{{
  let g:netrw_banner = 0
  let g:netrw_liststyle = 3
  let g:netrw_browse_split = 0
  let g:netrw_winsize = 20
  let g:netrw_list_hide = '.*\.png$,.*\.mp4,.*\.mp3,..*\.svg'
  function! OpenToRight()
    :normal v
    let g:path=expand('%:p')
    :q!
    execute 'belowright vnew' g:path
    :normal <C-w>l
  endfunction

  function! OpenBelow()
    :normal v
    let g:path=expand('%:p')
    :q!
    execute 'belowright new' g:path
    :normal <C-w>l
  endfunction

  function! OpenTab()
    :normal v
    let g:path=expand('%:p')
    :q!
    execute 'tabedit' g:path
    :normal <C-w>l
  endfunction


  function! NetrwMappings()
      " Hack fix to make ctrl-l work properly
      noremap <buffer> <A-l> <C-w>l
      noremap <buffer> <C-l> <C-w>l
      noremap <silent> <A-f> :call ToggleNetrw()<CR>
      noremap <buffer> V :call OpenToRight()<cr>
      noremap <buffer> H :call OpenBelow()<cr>
      noremap <buffer> T :call OpenTab()<cr>
      noremap <silent> <leader>n :call ToggleNetrw()<CR>
      noremap <silent> <leader>q :exit<CR>
  endfunction

  augroup netrw_mappings
      autocmd!
      autocmd filetype netrw call NetrwMappings()
  augroup END

  " Allow for netrw to be toggled
  function! ToggleNetrw()
      if g:NetrwIsOpen
          let i = bufnr("$")
          while (i >= 1)
              if (getbufvar(i, "&filetype") == "netrw")
                  silent exe "bwipeout " . i
              endif
              let i-=1
          endwhile
          let g:NetrwIsOpen=0
      else
          let g:NetrwIsOpen=1
          silent Lexplore
      endif
  endfunction

  " Check before opening buffer on any file
  function! NetrwOnBufferOpen()
    if exists('b:noNetrw')
        return
    endif
    call ToggleNetrw()
  endfun

  " Close Netrw if it's the only buffer open
  autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&filetype") == "netrw" || &buftype == 'quickfix' |q|endif

  " Make netrw act like a project Draw
  augroup ProjectDrawer
    autocmd!
		" Don't open Netrw
    autocmd VimEnter ~/.config/joplin/tmp/*,/tmp/calcurse*,~/.calcurse/notes/*,~/vimwiki/*,*/.git/COMMIT_EDITMSG let b:noNetrw=1
   autocmd VimEnter * :call NetrwOnBufferOpen()
   
  augroup END

let g:NetrwIsOpen=0

" }}}
" Vim-Airline {{{
let g:airline_theme='minimalist'
let g:airline_powerline_fonts = 1
" let g:airline_section_b = '%{getcwd()}' " in section B of the status line display the  
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#tabline#show_tabs = 0
let g:airline#extensions#tabline#enabled = 1           " enable airline tabline                                                           
let g:airline#extensions#tabline#show_close_button = 0 " remove 'X' at the end of the tabline                                            
let g:airline#extensions#tabline#tabs_label = ''       " can put text here like BUFFERS to denote buffers (I clear it so nothing is shown)
let g:airline#extensions#tabline#buffers_label = ''    " can put text here like TABS to denote tabs (I clear it so nothing is shown)      
let g:airline#extensions#tabline#fnamemod = ':t'       " disable file paths in the tab                                                    
let g:airline#extensions#tabline#show_tab_count = 0    " dont show tab numbers on the right                                                           
let g:airline#extensions#tabline#show_buffers = 0      " dont show buffers in the tabline                                                 
let g:airline#extensions#tabline#tab_min_count = 2     " minimum of 2 tabs needed to display the tabline                                  
let g:airline#extensions#tabline#show_splits = 0       " disables the buffer name that displays on the right of the tabline               
let g:airline#extensions#tabline#show_tab_nr = 0       " disable tab numbers                                                              
let g:airline#extensions#tabline#show_tab_type = 0     " disables the weird ornage arrow on the tabline
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
let g:OmniSharp_selector_ui = 'fzf'    " Use fzf.vim
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
