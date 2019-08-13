set number
let g:molokai_original = 1
let g:rehash256 = 1
colorscheme molokai
set showcmd
set mouse=a
set cursorline
set autoindent
set nocompatible
set history=1000
set autoread
set wildmenu
set cursorline
set ruler
set laststatus=2
set statusline+=%#warningmsg#
set statusline+=%{FugitiveStatusline()}
set ignorecase
set smartcase
set hlsearch
set showmatch
set encoding=utf8
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

noremap te :tabnew
noremap <C-h> gT
noremap <C-l> gt
inoremap <C-h> <C-o>gT
inoremap <C-l> <C-o>gt
map <C-n> :NERDTreeToggle<CR>
nmap <F8> :TagbarToggle<CR>
inoremap <C-g> <C-O>:
inoremap [ []
inoremap ( ()
inoremap { {}

execute pathogen#infect()
filetype plugin indent on
syntax on

"CPP Syntax
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1

"Javascript librairies syntax
let g:used_javascript_libs = 'underscore,backbone,jquery,angularjs,angularui,angularuirouter,vue,d3²,react'
