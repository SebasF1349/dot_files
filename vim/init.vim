" OPTIONS

set nocompatible
filetype plugin indent on

set encoding=utf-8

set number relativenumber
set autoindent                 " Minimal automatic indenting for any filetype.
set hidden                     " Possibility to have more than one unsaved buffers.
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch

set backspace=indent,eol,start " Allow backspacing over everything in insert mode.
set nolangremap
let &nrformats="bin,hex"
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set wildmenu		" display completion matches in a status line
set sidescroll=1
set sidescrolloff=2
set listchars=
set fillchars=
set autoread
set background=dark
set belloff=all
set cdpath=,.,~/src,~/
set clipboard=unnamed,unnamedplus
set cmdheight=1
set complete=.,w,b,u,t
set cscopeverbose
set diffopt=internal,filler
set display=lastline
set formatoptions=tcqj
let &keywordprg=":Man"
set nofsync
set guicursor=n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20
set hidden
set history=10000
set hlsearch
set nojoinspaces
set laststatus=2
set maxcombine=6
set mouse=a
set scroll=13
set sessionoptions-=options
set shortmess=filnxtToOF
set smarttab
set nostartofline
set tabpagemax=50
set tags=./tags;,tags
set notitle
set titleold=
set switchbuf=uselast
set ttimeout		" time out for key codes
set ttimeoutlen=100	" wait up to 100ms after Esc for special key
set scrolloff=8
set nrformats-=octal
if has('win32')
  set guioptions-=t
endif
set ttyfast
"TODO: set viewoptions+=unix,slash
set viewoptions-=options
let &viminfo='!,'.&viminfo
let &wildoptions="pum,tagfile"
let g:vimsyn_embed='l'

" DIRECTORIES

" These don't always necessarily exist in Neovim,
" but are convenient to have for Stdpath()

if ! exists('$XDG_CACHE_HOME')
  if has('win32')
    let $XDG_CACHE_HOME=$TEMP
  else
    let $XDG_CACHE_HOME=$HOME . '/.cache'
  endif
endif

if ! exists('$XDG_CONFIG_HOME')
  if has('win32')
    let $XDG_CONFIG_HOME=$LOCALAPPDATA
  else
    let $XDG_CONFIG_HOME=$HOME . '/.config'
  endif
endif

if ! exists('$XDG_DATA_HOME')
  if has('win32')
    let $XDG_DATA_HOME=$LOCALAPPDATA
  else
    let $XDG_DATA_HOME=$HOME . '/.local/share'
  endif
endif

" Similar to nvim's stdpath(id)
" Unfortunately, user functions can't use lowercase
function! Stdpath(id)
  if a:id == 'data'
    if has('win32')
      return $XDG_DATA_HOME . '/nvim-data'
    else
      return $XDG_DATA_HOME . '/nvim'
    endif
  elseif a:id == 'data_dirs'
    return []
  elseif a:id == 'config'
    return $XDG_CONFIG_HOME . '/nvim'
  elseif a:id == 'config_dirs' return []
  elseif a:id == 'cache'
    return $XDG_CACHE_HOME . '/nvim'
  else
    throw '"' . a:id . '" is not a valid stdpath'
  endif
endfunction

let s:datadir   = Stdpath('data')
let s:configdir = Stdpath('config')

" backupdir isn't set exactly like Neovim, because it's odd.
let &backupdir = s:datadir . '/backup//'
let &viewdir   = s:datadir . '/view//'
if ! executable('nvim')
  let &directory = s:datadir . '/swap//'
  let &undodir   = s:datadir . '/undo//'
else
  " Vim/Neovim have different file formats
  let &directory = s:datadir . '/vimswap//'
  let &undodir   = s:datadir . '/vimundo//'
endif

let s:shadadir   = s:datadir  . '/shada'
let &viminfofile.= s:shadadir . '/viminfo'

" Neovim creates directories if they don't exist
function! s:MakeDirs()
  for dir in [&backupdir, &directory, &undodir, &viewdir, s:shadadir]
    call mkdir(dir, "p")
  endfor
endfunction
autocmd VimEnter * call s:MakeDirs()

" Add user config dirs to search paths
function! s:fixpath(path)
  let l:pathprefix  = s:configdir . ',' . s:datadir . '/site,'
  let l:pathpostfix = ',' . s:datadir . '/site/after,' . s:configdir . '/after'
  let l:fullpath = l:pathprefix . a:path . l:pathpostfix
  " Remove .vim
  return substitute(l:fullpath, ','.$HOME.'\/\.vim\(/after\)\?', '', 'g')
endfunction

let &packpath     = s:fixpath(&packpath)
let &runtimepath  = s:fixpath(&runtimepath)

" AUTOCMD

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

let mapleader = " "

map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

nnoremap j gj
nnoremap k gk
nnoremap Y y$
nnoremap U <C-r>
nnoremap ' `
nnoremap ` '
nnoremap <C-q> <cmd>close<CR>
nnoremap <C-r> <C-w><C-w>
nnoremap <C-L> <Cmd>nohlsearch<Bar>diffupdate<CR><C-L>

inoremap <C-U> <C-G>u<C-U>
inoremap <C-W> <C-G>u<C-W>
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

" Implement Q
let g:qreg='@'
function! RecordOrStop()
  if reg_recording() == ''
    echo 'Enter register to record to: '
    let g:qreg=getcharstr()
    if g:qreg != "\e"
      execute 'normal! q'.g:qreg
    endif
  else
    normal! q
    call setreg(g:qreg, substitute(getreg(g:qreg), "q$", "", ""))
  endif
endfunction

" :MapQ will activate the Q mapping
command! MapQ noremap q <cmd>call RecordOrStop()<cr>
noremap Q <cmd>execute 'normal! @'.g:qreg<cr>

function! Toggle()
    let toggles = {
        \'true': 'false', 'false': 'true', 'True': 'False', 'False': 'True', 'TRUE': 'FALSE', 'FALSE': 'TRUE',
        \'yes': 'no', 'no': 'yes', 'Yes': 'No', 'No': 'Yes', 'YES': 'NO', 'NO': 'YES',
        \'on': 'off', 'off': 'on', 'On': 'Off', 'Off': 'On', 'ON': 'OFF', 'OFF': 'ON',
        \'open': 'close', 'close': 'open', 'Open': 'Close', 'Close': 'Open',
        \'dark': 'light', 'light': 'dark',
        \'width': 'height', 'height': 'width',
        \'first': 'last', 'last': 'first',
        \'top': 'right', 'right': 'bottom', 'bottom': 'left', 'left': 'center', 'center': 'top',
        \'and': 'or', 'or': 'and',
        \'=': '!', '!': '>', '>': '<', '<': '=',
        \'"': "'", "'": '`', '`': '"',
        \'&&': '||', '||': '&&',
    \}
    " && and || doesn't work as <cword> doesn't get symbols if there is text
    " after
    let word = getline('.')->slice(charcol('.') - 1, charcol('.'))
    if toggles->has_key(word)
        execute 'normal! "_s' .. toggles[word]
    else
        let word = expand("<cword>")
        if toggles->has_key(word)
            execute 'normal! "_ciw' .. toggles[word]
        endif
    endif
endfunction

nnoremap <silent> <BS> <cmd>call Toggle()<CR>
" DEFAULT PLUGINS

if has('syntax') && !exists('g:syntax_on')
  syntax enable
endif
if !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &rtp) ==# ''
  runtime! macros/matchit.vim
endif
if exists(":Man") != 2
  runtime! ftplugin/man.vim
endif

" GREP

if executable('rg') == 1
  let &grepprg='rg --vimgrep -uu '
  let &grepformat='%f:%l:%c:%m'
endif

" LOAD init.vim

" If this is the .vimrc, not a plugin, then load init.vim
if $MYVIMRC == expand('<sfile>:p')
  let $MYVIMRC = s:configdir . '/init.vim'
  if filereadable($MYVIMRC)
    source $MYVIMRC
  endif
endif

if &exrc && filereadable('.nvimrc')
  source .nvimrc
endif

" COLORSCHEME
colorscheme elflord
hi LineNr       ctermfg=DarkMagenta
" hi NonText      ctermfg=DarkBlue
" hi SpecialKey   ctermfg=DarkBlue
" hi ColorColumn  ctermbg=Black
