""""""""""""""""""
" display settings
""""""""""""""""""
" Show @@@ in the last line if it is truncated.
set display=truncate

" wrap or nowrap
set nowrap
set linebreak

" Show a few lines of context around the cursor.  Note that this makes the
" text scroll if you mouse-click near the start or end of the window.
set scrolloff=5

if $COLORTERM == 'truecolor' && has('termguicolors')
    set termguicolors
endif

if &diff
    colorscheme ron
endif
""""""""""""""""""""""
" display settings end
""""""""""""""""""""""


""""""""""""""""""""""
" indentation settings
""""""""""""""""""""""
set copyindent
set expandtab
set shiftwidth=2
""""""""""""""""""""""""""
" indentation settings end
""""""""""""""""""""""""""


"""""""""""""""""""
" keyboard settings
"""""""""""""""""""
" In many terminal emulators the mouse works just fine.  By enabling it you
" can position the cursor, Visually select and scroll with the mouse.
if has('mouse')
    set mouse=a
endif

noremap <Tab> :buffers<CR>:buffer<Space>
noremap <S-E> :Explore .<CR>
"""""""""""""""""""""""
" keyboard settings end
"""""""""""""""""""""""


"""""""""""""""
" misc settings
"""""""""""""""
" incrementally show the pattern for %s/pattern/substitute/
set incsearch

autocmd FileType modula2 setlocal spell spelllang=en_us
"""""""""""""""""""
" misc settings end
"""""""""""""""""""


"""""""""""""""""
" search settings
"""""""""""""""""
set ignorecase
set smartcase
set hlsearch
"""""""""""""""""""""
" search settings end
"""""""""""""""""""""


"""""""""""""""""
" syntax settings
"""""""""""""""""
set showmatch
"""""""""""""""""""""
" syntax settings end
"""""""""""""""""""""

""""""""""
" commands
""""""""""
" vim -b : edit binary using xxd-format!
" cf. /usr/share/vim/vim81/doc/tips.txt
augroup Binary
    au!
    au BufReadPre  *.bin let &bin=1
    au BufReadPost *.bin if &bin | %!xxd
    au BufReadPost *.bin set ft=xxd | endif
    au BufWritePre *.bin if &bin | %!xxd -r
    au BufWritePre *.bin endif
    au BufWritePost *.bin if &bin | %!xxd
    au BufWritePost *.bin set nomod | endif
augroup END

" Put these in an autocmd group, so that you can revert them with:
" ":augroup vimStartup | au! | augroup END"
augroup vimStartup
    au!

    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid, when inside an event handler
    " (happens when dropping a file on gvim) and for a commit message (it's
    " likely a different one than last time).
    autocmd BufReadPost *
                \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
                \ |   exe "normal! g`\""
                \ | endif

augroup END
""""""""""""""
" commands end
""""""""""""""

