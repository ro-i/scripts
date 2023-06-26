""""""""""""""""""
" display settings
""""""""""""""""""
" Show @@@ in the last line if it is truncated.
set display=truncate

" wrap or nowrap
set nowrap
set linebreak

" show line numbers
set number

" Show a few lines of context around the cursor.  Note that this makes the
" text scroll if you mouse-click near the start or end of the window.
set scrolloff=5

if $COLORTERM == 'truecolor' && has('termguicolors')
    set termguicolors
endif
""""""""""""""""""""""
" display settings end
""""""""""""""""""""""


""""""""""""""""""""""
" indentation settings
""""""""""""""""""""""
set copyindent

"autocmd Filetype haskell setlocal expandtab shiftwidth=4
set expandtab shiftwidth=4
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

" Disable Arrow keys in Escape mode
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
" Move by visual lines
map <silent> j gj
map <silent> k gk
map <silent> <Home> g<Home>
map <silent> <End> g<End>
map <silent> 0 g0
map <silent> ^ g^
map <silent> $ g$
"""""""""""""""""""""""
" keyboard settings end
"""""""""""""""""""""""


"""""""""""""""
" misc settings
"""""""""""""""
set clipboard+=unnamedplus

" all swap files should be in /tmp to reduce SSD-writes
set dir=/tmp

" keep 200 lines of command line history
set history=200

" incrementally show the pattern for %s/pattern/substitute/
set inccommand=nosplit

" do not keep a backup file
set nobackup

" enable spell checking for latex files
autocmd FileType tex setlocal spell spelllang=en_us

autocmd BufNewFile,BufRead *.pxi setlocal ft=pyrex
"""""""""""""""""""
" misc settings end
"""""""""""""""""""


""""""""""""""""""""""""""""
" misc settings for coc.nvim
" cf. https://github.com/neoclide/coc.nvim
""""""""""""""""""""""""""""
" TextEdit might fail if hidden is not set.
set hidden

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
    " Recently vim can merge signcolumn and number column into one
    set signcolumn=number
else
    set signcolumn=yes
endif

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
            \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Own enhancments.
noremap <silent> gb <C-o>
noremap <silent> gf <C-i>
noremap <S-Tab> :CocOutline<CR>

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
    if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
    elseif (coc#rpc#ready())
        call CocActionAsync('doHover')
    else
        execute '!' . &keywordprg . " " . expand('<cword>')
    endif
endfunction

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
    nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1, 1) : "\<C-f>"
    nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0, 1) : "\<C-b>"
    inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1, 1)\<cr>" : "\<Right>"
    inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0, 1)\<cr>" : "\<Left>"
    vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1, 1) : "\<C-f>"
    vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0, 1) : "\<C-b>"
endif

" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
"set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
""""""""""""""""""""""""""""""""
" misc settings for coc.nvim end
""""""""""""""""""""""""""""""""


"""""""""""""""""
" search settings
"""""""""""""""""
set ignorecase
set smartcase
au InsertEnter * set noignorecase
au InsertLeave * set ignorecase
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


"""""""""""""""""""""""""""""""""""""""""""""""
" vim-plug https://github.com/junegunn/vim-plug
"""""""""""""""""""""""""""""""""""""""""""""""
" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin(stdpath('data') . '/plugged')

"Plug 'HE7086/cyp-vim-syntax'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
"Plug 'neovim/nvim-lspconfig'
Plug 'neovimhaskell/haskell-vim'
Plug 'Vimjas/vim-python-pep8-indent'
Plug '~/dev/github/vim-monochrome'
"Plug 'lervag/vimtex'
Plug 'gabrielelana/vim-markdown'
"Plug 'junegunn/goyo.vim'
Plug '~/dev/github/llvm-project', {'dir': '~/dev/github/llvm-project/llvm/utils/vim'}
Plug '~/dev/github/llvm-project', {'dir': '~/dev/github/llvm-project/mlir/utils/vim'}
"Plug 'lark-parser/vim-lark-syntax'
Plug 'vim-autoformat/vim-autoformat'
"Plug 'nvim-tree/nvim-web-devicons' " optional, for file icons
"Plug 'nvim-tree/nvim-tree.lua'
Plug 'akinsho/toggleterm.nvim', {'tag' : '*'}

" Initialize plugin system
call plug#end()
""""""""""""""
" vim-plug end
""""""""""""""


"""" END

" vim-markdown
let g:markdown_enable_spell_checking = 0
let g:markdown_include_jekyll_support = 0

" vim-monochrome
let g:monochrome_italic_comments = 1
colo monochrome

" netrw
let g:netrw_altv = 1
let g:netrw_banner = 0
let g:netrw_browse_split = 0
let g:netrw_liststyle = 3
"let g:netrw_winsize = 20
augroup netrw_mapping
    autocmd!
    autocmd filetype netrw call NetrwMapping()
augroup END

function! NetrwMapping()
    nmap <buffer> h -
    nmap <buffer> l <CR>
endfunction

" vim-autoformat
map F :Autoformat<CR>
