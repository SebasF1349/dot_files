set nocompatible
filetype plugin indent on
syntax on
set encoding=utf-8
set background=dark

" --- Security / safety ---
set nomodeline
set modelines=0
set viminfo=
set noundofile
set nobackup
set writebackup

" --- UI ---
set number
set ruler
set showcmd
set laststatus=2
set scrolloff=8
set nowrap
set list
set listchars=tab:>-,trail:.
set splitbelow splitright
set wrap

" --- Search ---
set hlsearch
set incsearch
set ignorecase
set smartcase

" --- Editing ---
set backspace=indent,eol,start
set autoindent
set tabstop=4 shiftwidth=4 softtabstop=4
set expandtab
set smarttab
set hidden
set nojoinspaces

" --- Completion / responsiveness ---
set wildmenu
set wildmode=longest:full,full
let &wildoptions="pum,tagfile"
set pumheight=10
set complete=.,w,b,u,t
set completeopt=menuone,noselect
set ttimeout
set ttimeoutlen=50

" --- Per-filetype indentation common on servers ---
augroup server_ft
  autocmd!
  autocmd FileType yaml,json,sh,bash,nginx,terraform setlocal shiftwidth=2 softtabstop=2 tabstop=2
  autocmd FileType make setlocal noexpandtab
augroup END

" --- Mappings ---
let mapleader = " "
nnoremap Y y$
nnoremap <silent> <C-l> :nohlsearch<CR><C-l>
vnoremap < <gv
vnoremap > >gv

" --- WezTerm integration over SSH (OSC sequences) ---
function! s:Emit(seq) abort
  if empty($SSH_CONNECTION) || !exists('*echoraw')
    return
  endif
  call echoraw(a:seq)
endfunction

function! s:SetIsSshVim(val) abort
  let l:b64 = a:val ==# 'true' ? 'dHJ1ZQ==' : 'ZmFsc2U='   " base64 of true / false
  call s:Emit("\<Esc>]1337;SetUserVar=IS_SSH_VIM=" . l:b64 . "\x07")
endfunction

augroup wezterm_uservar
  autocmd!
  autocmd VimEnter,VimResume  * call s:SetIsSshVim('true')
  autocmd VimLeave,VimSuspend * call s:SetIsSshVim('false')
augroup END

" Copy text to the local clipboard (OSC 52, write-only)
function! s:Osc52Send(text) abort
  let l:b64 = substitute(system('base64', a:text), '\n', '', 'g')
  if v:shell_error == 0 && !empty(l:b64)
    call s:Emit("\<Esc>]52;c;" . l:b64 . "\x07")
  endif
endfunction

" gy{motion} / visual gy: yank and send to the local clipboard
function! s:GyOp(type) abort
  let l:sel = &selection
  set selection=inclusive
  if a:type ==# 'line'
    silent execute "normal! '[V']y"
  elseif a:type ==# 'char'
    silent execute "normal! `[v`]y"
  elseif a:type ==# 'block'
    silent execute "normal! `[\<C-v>`]y"
  else
    " called from visual mode (v, V or CTRL-V)
    silent execute "normal! gvy"
  endif
  let &selection = l:sel
  let l:text = getreg('"')
  if getregtype('"') ==# 'V' && l:text[-1:] !=# "\n"
    let l:text .= "\n"
  endif
  call s:Osc52Send(l:text)
endfunction

nnoremap <silent> gy :set operatorfunc=<SID>GyOp<CR>g@
nnoremap <silent> gyy :set operatorfunc=<SID>GyOp<CR>g@_
xnoremap <silent> gy :<C-u>call <SID>GyOp(visualmode())<CR>

