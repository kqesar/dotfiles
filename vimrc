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
let mapleader=","
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4
set autoread
set autowrite
set foldmethod=syntax
set nofoldenable
set incsearch
filetype plugin indent on
syntax on
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
noremap <C-h> <C-w>h
noremap <C-l> <C-w>l

"Verification si NeoBundle est installé"
if !isdirectory(expand("~/.vim/bundle/neobundle.vim"))
    echom "Installation de NeoBundle"
    echom system("curl https://raw.githubusercontent.com/Shougo/neobundle.vim/master/bin/install.sh > install.sh")
    echom system("sh ./install.sh") 
    echom "Fin de l'installation de NeoBundle"
endif

"NeoBundle Scripts-----------------------------
" Required:
set runtimepath+=~/.vim/bundle/neobundle.vim/

" Required:
call neobundle#begin(expand('~/.vim/bundle'))

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
NeoBundle 'leafgarland/typescript-vim'
NeoBundle 'fatih/vim-go'
NeoBundle 'lumiliet/vim-twig'
NeoBundle 'vim-ruby/vim-ruby'
NeoBundle 'tpope/vim-rails'
NeoBundle 'hdima/python-syntax'
NeoBundle 'tbastos/vim-lua'
NeoBundle 'tpope/vim-surround'
NeoBundle 'kchmck/vim-coffee-script'
NeoBundle 'easymotion/vim-easymotion'
NeoBundle 'yggdroot/indentline'
NeoBundle 'rdnetto/YCM-Generator'
NeoBundle 'myhere/vim-nodejs-complete'
NeoBundle 'moll/vim-node'
NeoBundle 'rust-lang/rust.vim'
NeoBundle 'racer-rust/vim-racer'
NeoBundle 'ludovicchabant/vim-gutentags'
NeoBundle 'klen/python-mode'
NeoBundle 'ryanoasis/vim-devicons'
NeoBundle 'tiagofumo/vim-nerdtree-syntax-highlight'
NeoBundle 'Shougo/vimshell', { 'rev' : '3787e5' }
call neobundle#end()

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck
"End NeoBundle Scripts-------------------------

"CPP Syntax
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_experimental_simple_template_highlight = 1
let g:cpp_concepts_highlight = 1

"Javascript librairies syntax
let g:used_javascript_libs = 'underscore,backbone,jquery,angularjs,angularui,angularuirouter,vue,d3²,react'

"airline
let g:airline_powerline_fonts = 1
let g:airline_theme='molokai'
let g:airline#extensions#tabline#enabled = 1

"Typescript config
let g:typescript_indent_disable = 1

"Conf ternjs
let tern#is_show_argument_hints_enabled=1

"Indent guide"
let g:indentLine_enabled = 1
let g:indentLine_char_list = ['|', '¦', '┆', '┊']

"Conf vim-go
" go-vim plugin specific commands
" Also run `goimports` on your current file on every save
" Might be be slow on large codebases, if so, just comment it out
let g:go_fmt_command = "goimports"
let g:go_autodetect_gopath = 1
let g:go_list_type = "quickfix"

let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_generate_tags = 1

" Status line types/signatures.
let g:go_auto_type_info = 1

"YCM"
let g:ycm_global_ycm_extra_conf = "~/.vim/bundle/youcompleteme/third_party/ycmd/cpp/ycm/.ycm_extra_conf.py"
let g:ycm_auto_trigger = 1
let g:ycm_complete_in_strings = 1
let g:ycm_complete_in_comments = 1
let g:ycm_min_num_of_chars_for_completion = 2

"Python config
let g:python_highlight_all = 1

"Syntastic"
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

function! EditBashRc()
    :e ~/.bashrc
endfunction

function! EditZshrc()
    :e ~/.zshrc
endfunction

function! EditVimRc()
    :e ~/.vimrc
endfunction

augroup assembly
    autocmd!
    autocmd BufWritePost *.asm :echom system("make")<CR>
    autocmd FileType asm map <F1> :echom system("make")<CR>
augroup END

augroup golang
    autocmd!
    autocmd BufWritePost *.go :GoBuild<CR>
    autocmd FileType go  noremap <F1> :GoBuild<CR>
    autocmd FileType go  noremap <F2> :GoRun<CR>
augroup END

