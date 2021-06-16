function! myspacevim#after() abort
        noremap n j|noremap e k|noremap i l
        noremap l i|noremap L I
        noremap k n|noremap K N
        noremap j e
        nmap <BS> <C-^>
        "noremap ' `|noremap ` '
        " The best!
        "noremap ; :|noremap : ;
        " Sane redo.
        noremap U <C-r>
        noremap Y y$
        cnoremap w!! execute 'silent! write !SUDO_ASKPASS=`which ssh-askpass` sudo tee % >/dev/null' <bar> edit!
        noremap <leader>rp :%s//g<left><left>
        noremap  <leader>rw :%s/<C-r><C-w>//g<left><left>
        noremap H <C-w>h|noremap I <C-w>l|noremap N <C-w>j|noremap E <C-w>k
  endfunction



