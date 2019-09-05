set number
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
set encoding=UTF-8
set noswapfile
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
noremap <Tab> :bn<CR>
noremap <S-Tab> :bp<CR>
noremap <C-x> :bd<CR>
inoremap <C-h> <C-o>gT
inoremap <C-l> <C-o>gt
map <C-n> :NERDTreeToggle<CR>
nmap <F8> :TagbarToggle<CR>
inoremap <C-g> <C-O>:
inoremap [ []<Left>
inoremap ( ()<Left>
inoremap { {}<Left>
inoremap " ""<Left>
inoremap ' ''<Left>
noremap <C-w> <C-w>w
noremap <C-h> <C-w>h
noremap <C-l> <C-w>l

"NeoBundle Scripts-----------------------------
" Required:
set runtimepath+=/home/kqesar/.vim/bundle/neobundle.vim/

" Required:
call neobundle#begin(expand('/home/kqesar/.vim/bundle'))

" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

" Add or remove your Bundles here:
NeoBundle 'Shougo/neosnippet.vim'
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'ctrlpvim/ctrlp.vim'
NeoBundle 'flazz/vim-colorschemes'
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'vim-airline/vim-airline'
NeoBundle 'vim-airline/vim-airline-themes'
NeoBundle 'enricobacis/vim-airline-clock'
NeoBundle 'stanangeloff/php.vim'
NeoBundle 'ap/vim-css-color'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'w0rp/ale'
NeoBundle 'majutsushi/tagbar'
NeoBundle 'airblade/vim-gitgutter'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'alvan/vim-closetag'
NeoBundle 'cakebaker/scss-syntax.vim'
NeoBundle 'othree/html5.vim'
NeoBundle 'pangloss/vim-javascript'
NeoBundle 'stanangeloff/php.vim'
NeoBundle 'octol/vim-cpp-enhanced-highlight'
NeoBundle 'valloric/youcompleteme'
NeoBundle 'ervandew/supertab'
NeoBundle 'marijnh/tern_for_vim'
NeoBundle 'grep.vim'
NeoBundle 'airblade/vim-rooter'

" You can specify revision/branch/tag.
NeoBundle 'Shougo/vimshell', { 'rev' : '3787e5' }

call neobundle#end()
filetype plugin indent on
syntax on
filetype plugin on



" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck
"End NeoBundle Scripts-------------------------


"CPP Syntax
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1

"Javascript librairies syntax
let g:used_javascript_libs = 'underscore,backbone,jquery,angularjs,angularui,angularuirouter,vue,d3²,react'

"airline
let g:airline_powerline_fonts = 1
let g:airline_theme='molokai'
let g:airline#extensions#tabline#enabled = 1

"Conf ternjs
let tern#is_show_argument_hints_enabled=1
function! CompileScss()
    let g:scss_folder = 'src/scss/'
    let g:css_folder = 'dist/css/'
    execute "!sass " . g:scss_folder . "main.scss " . g:css_folder . "style.css"
endfunction
autocmd BufWritePost *.scss :call CompileScss()
autocmd BufWritePost ~/.bashrc :!source ~/.bashrc<CR>
autocmd BufWritePost *.asm :!make<CR>

augroup assembly
    autocmd FileType asm map <F1> :echom system("make")<CR>
augroup END
