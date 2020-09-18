" Vim Plug {{{
let mapleader=" "
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" }}}
call plug#begin('~/.config/nvim/plugged')
" Provides asynchronous execution.
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
" nvim ui{{{
Plug 'vim-airline/vim-airline'
Plug 'vim-syntastic/syntastic'
Plug 'vim-airline/vim-airline-themes'
Plug 'dikiaap/minimalist' "The neovim color theme.
Plug 'Shougo/defx.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'kristijanhusak/defx-git' " Git status column for defx
"Plug 'altercation/vim-colors-solarized'
Plug 'arcticicestudio/nord-vim'
Plug '907th/vim-auto-save'
Plug 'preservim/nerdcommenter'
"}}}
"intergrate fzf with vim {{{ fuzzy finding of files" Layout Look n Feal {{{
" Plug 'itchyny/lightline.vim' " A light and configurable statusline/tabline plugin for Vim
Plug 'christoomey/vim-tmux-navigator'
Plug 'djoshea/vim-autoread'
"Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
"Plug 'OmniSharp/omnisharp-vim'
"}}}
" Git {{{
" Plug 'airblade/vim-gitgutter'
 "Plug 'airblade/vim-rooter'
" }}}
" Markdown Support{{{
" Track the engine
Plug 'SirVer/ultisnips' 
Plug 'honza/vim-snippets' " tabular plugin is used to format tables
Plug 'godlygeek/tabular' " JSON front matter highlight plugin
Plug 'plasticboy/vim-markdown' " Markdown Previewing
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }}
" }}}

" Plugin --Editing {{{
" Plug 'tpope/vim-abolish' " easily search for, substitute, & abbreviate multiple variants of a word
"}}}
" Syntax highlingt for most languages {{{
Plug 'sheerun/vim-polyglot'
" }}}
" Javascript snippets
Plug 'pangloss/vim-javascript' " JS syntax highlighting and indentation
Plug 'leafgarland/typescript-vim' " TS syntax highlighting
Plug 'maxmellon/vim-jsx-pretty' " JSX and TSX syntax highlighting
Plug 'epilande/vim-es2015-snippets'
Plug 'epilande/vim-react-snippets'
" Conquer of Completion {{{
"}}}
Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release' }
let g:coc_global_extensions=['coc-eslint', 'coc-json', 'coc-tsserver', 'coc-omnisharp', 'coc-docker',  'coc-html' , 'coc-css' ,  'coc-jest', 'coc-snippets', 'coc-markdownlint']


call plug#end()

" AutoSave Settings {{{
let g:auto_save =1 "enable Autosave on Vim startupx
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
augroup mygroup
    autocmd!
    " Setup formatexpr specified filetype(s).
    autocmd FileType typescript,typescriptreact,javascript,javascriptreact,json setl formatexpr=CocAction('formatSelected')
    " Update signature help on jump placeholder
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
    " Update signature help on jump placeholder
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end
" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')
" }}}

nnoremap <silent> <Leader><leader> :Defx<CR>
  call defx#custom#option('_', {
      \ 'columns': 'git:indent:icon:filename',
      \ 'winwidth':30,
      \ 'split': 'vertical',
      \ 'direction': 'topleft',
      \ 'show_ignored_files': 0,
      \ 'buffer_name': 'Files',
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
"OmniSharp {{{
" Use Roslyin and also better performance than HTTP
let g:OmniSharp_server_stdio = 1
let g:omnicomplete_fetch_full_documentation = 1


" Timeout in seconds to wait for a response from the server
let g:OmniSharp_timeout = 30


let g:OmniSharp_popup_options = {
\ 'highlight': 'Normal',
\ 'padding': [1],
\ 'border': [1]
\}

let g:syntastic_cs_checkers = ['code_checker']
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0
"}}}

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

" Vim Airline {{{
"

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 0
let g:airline_theme='minimalist'
let g:airline#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#coc#enabled = 1
let g:airline_powerline_fonts=1

" Just show the filename (no path) in the tab
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
" }}}
let g:UltiSnipsExpandTrigger="<c-j>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
" fzf
nnoremap <C-p> :FzfGFiles<CR>
nnoremap <leader>b :FzfBuffers<CR>
nnoremap <leader>gs :FzfFiles<CR> 
nnoremap gl :FzfBLines<CR>
nnoremap <C-f> :FzfRg!<CR>


" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
"
inoremap <silent><expr> <C-;> coc#refresh()

" To make <cr> select the first completion item and confirm the completion
" when item has been selected.
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"
" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>cf  <Plug>(coc-fix-current)
" Use K to show documentation in preview window.
nnoremap <silent><leader>s :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)


" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')



function! StatusDiagnostic() abort
  let info = get(b:, 'coc_diagnostic_info', {})
  if empty(info) | return '' | endif
  let msgs = []
  if get(info, 'error', 0)
    call add(msgs, 'E' . info['error'])
  endif
  if get(info, 'warning', 0)
    call add(msgs, 'W' . info['warning'])
  endif
  return join(msgs, ' ') . ' ' . get(g:, 'coc_status', '')
endfunction


" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}%{StatusDiagnostic()}
" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>d  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.~/.config/nvim/plugins.vim
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>S  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>

" Colors (Always at bottom of .vimrc)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set background=dark
colorscheme nord
