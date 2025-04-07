""""""""""""""""""
" display settings
""""""""""""""""""
set nowrap
set linebreak

" Show a few lines of context around the cursor.  Note that this makes the
" text scroll if you mouse-click near the start or end of the window.
set scrolloff=5

if &diff
  colorscheme ron
elseif has('nvim')
  colorscheme vim
else
  colorscheme default
endif

""""""""""""""""""""""
" indentation settings
""""""""""""""""""""""
set copyindent
set expandtab
set shiftwidth=2

"""""""""""""""""""
" keyboard settings
"""""""""""""""""""
" In many terminal emulators the mouse works just fine.  By enabling it you
" can position the cursor, Visually select and scroll with the mouse.
if has('mouse')
    set mouse=a
endif

let g:mapleader = ' '
let g:maplocalleader = ' '
noremap <Leader><Leader> :Buffers<CR>
noremap <Leader>f :Files<CR>

"""""""""""""""
" misc settings
"""""""""""""""
" incrementally show the pattern for %s/pattern/substitute/
set incsearch

set clipboard=unnamedplus

autocmd BufRead,BufNewFile *.md setlocal spell
autocmd FileType gitcommit setlocal spell

"""""""""""""""""
" search settings
"""""""""""""""""
set ignorecase
set smartcase
set hlsearch

"""""""""""""""""
" syntax settings
"""""""""""""""""
set showmatch

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

"""""""""
" plugins
"""""""""
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'llvm/llvm.vim'
call plug#end()

