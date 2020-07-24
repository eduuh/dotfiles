" The idea is to use HNEI as arrows – keeping the traditional Vim homerow style – and changing as
" little else as possible. This means JKL are free to use and NEI need new keys.
" - k/K is the new n/N.
" - s/S is the new i/I ["inSert"].
" - j/J is the new e/E ["Jump" to EOW].
" - l/L skip to the beginning and end of lines. Much more intuitive than ^/$.
" - Ctrl-l joins lines, making l/L the veritable "Line" key.
" - r replaces i as the "inneR" modifier [e.g. "diw" becomes "drw"].
" Colemak Remaps {{{

" HNEI arrows. Swap 'gn'/'ge' and 'n'/'e'.
noremap n gj|noremap e gk|noremap i l|noremap gn j|noremap ge k
" In(s)ert. The default s/S is synonymous with cl/cc and is not very useful.
noremap s i|noremap S I
" Repeat search.
noremap k n|noremap K N
" BOL/EOL/Join.
noremap l ^|noremap L $|noremap <C-l> J
" _r_ = inneR text objects.
onoremap r i
" EOW.
noremap j e|noremap J E
" Faster in-line navigation
nmap <BS> <C-^>

" Jump to exact mark location with ' instead of line.
noremap ' `|noremap ` '
" The best!
noremap ; :|noremap : ;

" Sane redo.
noremap U <C-r>

" Y consistent with C and D
noremap Y y$

cmap w!! w !sudo tee %
" Remapping for Ale {{{

" Better tabbing
vnoremap < <gv
vnoremap > >gv

" Switch tabs with ctrl
" Switch panes with Shift.
noremap H <C-w>h|noremap I <C-w>l|noremap N <C-w>j|noremap E <C-w>k
" Moving windows around.
noremap <C-w>N <C-w>J|noremap <C-w>E <C-w>K|noremap <C-w>I <C-w>L
" High/Low. Mid remains `M` since <C-m> is unfortunately interpreted as <CR>.
noremap <C-e> H|noremap <C-n> L

" Scroll up/down.
noremap zn <C-y>|noremap ze <C-e>
" Back and forth in jump and changelist.
nnoremap gh <C-o>|nnoremap gi <C-i>|nnoremap gH g;|nnoremap gI g,

" Easy CAPS
inoremap <c-u> <ESC>viwUi
nnoremap <c-u> viwU<Esc>
" Use alt + hjkl hnei to resize windows
" nnoremap <M-n>    :resize -2<CR>
" nnoremap <M-e>    :resize +2<CR>
" nnoremap <M-i>    :vertical resize -2<CR>
" nnoremap <M-h>    :vertical resize +2<CR>
" }}}

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
" Move the tabs with tmn and tmi;:
noremap tmp :-tabmove<CR>
noremap tmn :+tabmove<CR>

"Press <space> + q to close the window below the current window.
 
" }}}
