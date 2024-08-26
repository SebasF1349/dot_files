if &compatible
  set nocompatible
endif

" Allow backspacing over everything in insert mode.
set backspace=indent,eol,start

set history=1000
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set wildmenu		" display completion matches in a status line
set laststatus=2
set sidescroll=1
set sidescrolloff=2
set listchars=

set ttimeout		" time out for key codes
set ttimeoutlen=100	" wait up to 100ms after Esc for special key

set display=

set scrolloff=8

set nrformats-=octal

if has('win32')
  set guioptions-=t
endif

filetype plugin indent on

augroup vimStartup
autocmd!

autocmd BufReadPost *
  \ let line = line("'\"")
  \ | if line >= 1 && line <= line("$") && &filetype !~# 'commit'
  \      && index(['xxd', 'gitrebase'], &filetype) == -1
  \ |   execute "normal! g`\""
  \ | endif

augroup END

augroup vimHints
au!
autocmd CmdwinEnter *
  \ echohl Todo |
  \ echo gettext('You discovered the command-line window! You can close it with ":q".') |
  \ echohl None
augroup END

syntax on
let c_comment_strings=1

set number relativenumber
set autoindent                 " Minimal automatic indenting for any filetype.
set hidden                     " Possibility to have more than one unsaved buffers.
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch

let mapleader = " "

map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

nnoremap Q @q
nnoremap j gj
nnoremap k gk
nnoremap Y y$
nnoremap U <C-r>
nnoremap ' `
nnoremap ` '
nnoremap <C-q> <cmd>close<CR>
nnoremap <C-r> <C-w><C-w>

inoremap <C-U> <C-G>u<C-U>
inoremap jk <esc>

vnoremap < <gv
vnoremap > >gv
vnoremap S) <esc>`>a)<esc>`<i(<esc>
vnoremap S( <esc>`>a)<esc>`<i(<esc>
vnoremap S] <esc>`>a]<esc>`<i[<esc>
vnoremap S[ <esc>`>a]<esc>`<i[<esc>
vnoremap S} <esc>`>a}<esc>`<i{<esc>
vnoremap S{ <esc>`>a}<esc>`<i{<esc>
vnoremap S" <esc>`>a"<esc>`<i"<esc>
vnoremap S' <esc>`>a'<esc>`<i'<esc>
vnoremap S` <esc>`>a`<esc>`<i`<esc>


cnoremap <C-A> <Home>
cnoremap <C-E> <End>
cnoremap <C-K> <C-U>
cnoremap <C-P> <Up>
cnoremap <C-N> <Down>
