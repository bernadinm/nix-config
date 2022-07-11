" ============================================================================
" GENERAL
" ============================================================================


" Enable filetype plugins
filetype plugin indent on
syntax enable

" Resize vim upon resize eg. pane sizing when resizing terminal window
au VimResized * exe "normal! \<c-w>="

set encoding=utf8
set nocompatible
set clipboard=unnamed                         " use system clipboard, vim must have +clipboard
set noreadonly                                " for vimdiff
set history=1000                              " Sets how many lines of history VIM has to remember
set ttyfast                                   " send more characters for faster redraws
set lazyredraw                                " Don't redraw while executing macros
set autoread                                  " update when a file is changed from the outside
" reload buffer when moving around for file changes from outside
" https://vi.stackexchange.com/questions/444/how-do-i-reload-the-current-file
au FocusGained,BufEnter * :checktime
set showcmd                                   " Show incomplete cmds down the bottom
set hidden                                    " A buffer becomes hidden when it is abandoned
set ignorecase smartcase hlsearch incsearch   " Search settings
set nobackup nowb noswapfile                  " No vim backup files
set ffs=unix,dos,mac                          " Use Unix as the standard file type
set noerrorbells novisualbell t_vb= tm=500    " No annoying sound on errors
set backspace=eol,start,indent                " Configure backspace so it acts as it should act
set whichwrap+=<,>,h,l                        " automatically wrap left and right
set relativenumber                            " show relative number from curent line
set t_Co=256                                  " 256 colors in vim
set textwidth=80 colorcolumn=80 lbr tw=80     " set line break to 80
set number numberwidth=2                      " show line number in left margin
set cursorline!                               " highlight current cursor's line
set ruler laststatus=2 title                  " Sets ruler show current line
set magic                                     " For regular expressions turn magic on
set showmatch                                 " Show matching brackets when text indicator is over them
set mat=2                                     " How many tenths of a second to blink when matching brackets
set wildmenu                                  " Turn on the WiLd menu
set wildmode=list:longest,full
set wildignorecase
set wildignore=*.o,*~,*.pyc                   " Ignore compiled files
set shiftwidth=2 tabstop=2 expandtab smarttab " tab space
set wrap                                      " Wrap lines
set cmdheight=2                               " Display for messages
set updatetime=300
set signcolumn=yes
set copyindent                                " Paste mode
set iskeyword+=- " treat dash as word
" for markdown
" https://github.com/plasticboy/vim-markdown/#options
set conceallevel=2

autocmd BufWritePre * :%s/\s\+$//e            " Clear trailing spaces on save

" File types
au BufRead,BufNewFile *.ejs,*.handlebars set filetype=html
au BufRead,BufNewFile *.css set filetype=scss.css
au BufRead,BufNewFile *.scss set filetype=scss
au BufRead,BufNewFile *.js set filetype=javascript
au BufRead,BufNewFile *.conf set filetype=nginx
au BufRead,BufNewFile *.sls,*.{yaml,yml},*.service set filetype=yaml
au BufRead,BufNewFile *.ts,*.tsx set filetype=typescript.tsx
au BufRead,BufNewFile *.groovy set filetype=Jenkinsfile
au BufRead,BufNewFile *.Dockerfile set filetype=dockerfile
au BufRead,BufNewFile .bazelrc set filetype=conf

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType scss.css set omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
autocmd FileType json syntax match Comment +\/\/.\+$+

" vimdiff, ignore whitespace
if &diff
  " diff mode
  set diffopt+=iwhite
  map gs :call IwhiteToggle()<CR>
  function! IwhiteToggle()
    if &diffopt =~ 'iwhite'
      set diffopt-=iwhite
    else
      set diffopt+=iwhite
    endif
  endfunction
endif

" ============================================================================
" KEYBINDINGS
" ============================================================================

" Set Leader
let g:mapleader = ","
" save and quit
map <leader>w :w!<cr>
map <leader>q :qa<cr>
" jk to escape from all modes
imap jk <Esc>
" control a/e will go back and front of line
imap <C-a> <esc>I
imap <C-e> <esc>A
" tab buffer shortcuts
nmap <leader>[ :bprevious<CR>
nmap <leader>] :bnext<CR>
nmap <leader>d :BD<CR>
" Shorten next window command
" see more here
" :help <C-w>
map <C-w> <C-w>w
" next search will center screen
nnoremap n nzzzv
nnoremap N Nzzzv
" replace word under cursor
nnoremap <leader>r :%s/\<<C-r><C-w>\>//g<Left><Left>
" move up and down wrapped lines
nnoremap j gj
nnoremap k gk
" capitol movement keys will do sensible corresponding movement
noremap H ^
noremap L g_
noremap J 6j
noremap K 6k
noremap <leader>1 :%bd\|e#<CR>
" clear search highlight
nnoremap <leader><space> :nohlsearch<cr>
" shortcut for visual mode sort
vnoremap <leader>s :sort
" do not override register when pasting
xnoremap p pgvy
" execute macro on every line of visual selection
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
map <leader>e :Explore<CR>
let g:netrw_list_hide = '^\..*'
let g:netrw_hide = 1

" ============================================================================
" VIM_PLUG
" ============================================================================
" Plug 'airblade/vim-rooter'
let g:rooter_patterns = ['Makefile', '.git/']
" ================================================================ NAVIGATION "
set rtp+=~/.fzf
" preview
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \ "rg --column --line-number --no-heading --color=always --smart-case ".shellescape(<q-args>),
  \ 1,
  \ fzf#vim#with_preview(),
  \ <bang>1)

command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>1)

" Search from project root (.git)
" https://github.com/junegunn/fzf.vim/issues/47#issuecomment-160237795
function! s:find_git_root()
  return system('git rev-parse --show-toplevel 2> /dev/null')[:-2]
endfunction

command! ProjectFiles execute 'Files' s:find_git_root()
" custom search
nmap <C-p> :ProjectFiles<cr>
nmap <leader>a :Rg<cr>

" Plug 'junegunn/fzf.vim'
" This is the default extra key bindings
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }
" Default fzf layout
" - down / up / left / right
let g:fzf_layout = { 'down': '~40%' }
" Customize fzf colors to match your color scheme
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

" Plug 'preservim/nerdtree'
let g:NERDTreeWinSize=50
let g:NERDTreeMinimalUI = 1
let g:NERDTreeIgnore=['node_modules', 'bazel-out', '_backend.tf', '_providers.tf']
nmap <C-n> :NERDTreeToggle<CR>
nmap <leader>f :NERDTreeFind<CR>
" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

" coc
call plug#begin(stdpath('data') . '/plugged')
Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-prettier', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-eslint', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-yaml', {'do': 'yarn install --frozen-lockfile'}
Plug 'fannheyward/coc-pyright', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-json', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-highlight', {'do': 'yarn install --frozen-lockfile'} " color highlighting
Plug 'josa42/coc-docker', {'do': 'yarn install --frozen-lockfile'}
Plug 'josa42/coc-sh', {'do': 'yarn install --frozen-lockfile'}
Plug 'ryanoasis/vim-devicons'
Plug 'vwxyutarooo/nerdtree-devicons-syntax'

" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()
" Use K to show documentation in preview window
nnoremap <silent> <C-a> :call <SID>show_documentation()<CR>
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
inoremap <silent><expr> <c-space> coc#refresh()
" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)
" Remap keys for gotos
nmap <C-]> <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Use K to show documentation in preview window
nnoremap <leader>m :call <SID>show_documentation()<CR>

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Snippets
" Plug 'SirVer/ultisnips'
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<c-k>"
let g:UltiSnipsJumpForwardTrigger="<c-k>"
let g:UltiSnipsJumpBackwardTrigger="<c-bk>"
let g:UltiSnipsSnippetsDir = "~/.dotfiles/vim/UltiSnips"
let g:UltiSnipsSnippetDirectories=[$HOME . '/.dotfiles/vim/UltiSnips']

" Plug 'terryma/vim-multiple-cursors'
let g:multi_cursor_use_default_mapping=0
" Default mapping
let g:multi_cursor_start_word_key      = '<C-k>'
let g:multi_cursor_next_key            = '<C-k>'
let g:multi_cursor_skip_key            = '<C-x>'
let g:multi_cursor_quit_key            = '<Esc>'

" Plug 'easymotion/vim-easymotion'
" easy motion trigger with 's'
let g:EasyMotion_do_mapping = 0
nmap s <Plug>(easymotion-overwin-f2)
let g:EasyMotion_smartcase = 1
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
" override default search /
" map / <Plug>(easymotion-sn)
" omap / <Plug>(easymotion-tn)
let g:EasyMotion_user_smartsign_us = 1
" Plug 'Raimondi/delimitMate'
let delimitMate_expand_cr=1
au FileType mail let b:delimitMate_expand_cr = 1
" ======================================================================= GIT "
" Jump to github line
" blob view <leader>gh
" blame view <leader>gb
" Plug 'ruanyl/vim-gh-line'
let g:gh_user_canonical = 1 " Use branch name when possible
" shortcut Gblame
nnoremap <leader>g :Git blame<cr>
" ==================================================================== SYNTAX "
" Plug 'hashivim/vim-terraform'
let g:terraform_align=1
let g:terraform_fmt_on_save=1
" Plug 'elzr/vim-json'
let g:vim_json_syntax_conceal = 0
" ==================================================================== GOLANG "
" Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
let g:go_doc_keywordprg_enabled = 0
let g:go_fmt_command = "goimports"
let g:go_def_mode = 'godef'

" ====================================================================== RUST "
" Plug 'rust-lang/rust.vim'
let g:rustfmt_autosave = 1
" ================================================================ JAVASCRIPT "
" Plug 'mattn/emmet-vim'
let g:user_emmet_leader_key='<C-Z>'
" Plug 'evanleck/vim-svelte', {'branch': 'main'}
let g:svelte_preprocessors = ['typescript']

let base16colorspace=256        " Let base16 access colors present in 256 colorspace
" Using Tokyonight vim theme
" let g:tokyonight_transparent = "true"
let g:tokyonight_style = "night"
let g:tokyonight_italic_functions = 1
let g:tokyonight_sidebars = [ "qf", "vista_kind", "terminal", "packer" ]

" Change the "hint" color to the "orange" color, and make the "error" color bright red
let g:tokyonight_colors = {
  \ 'hint': 'orange',
  \ 'error': '#ff0000'
\ }

" Load the colorscheme
colorscheme tokyonight

" Telescope-vim
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" https://github.com/google/vim-codefmt
augroup autoformat_settings
  autocmd FileType bzl AutoFormatBuffer buildifier
augroup END

let g:vim_markdown_folding_disabled = 1

call plug#end()

" ============================================================================
" Windows WSL
" ============================================================================

" Setup yanking from vim to windows clipboard
if system('uname -r') =~ "microsoft"
  augroup Yank
    autocmd!
    autocmd TextYankPost * :call system('clip.exe ',@")")
  augroup END
endif

set secure
