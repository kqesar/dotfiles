autocmd!

function! MvnInstall()
    :terminal mvn clean install
endfunction

function! MvnPackage()
    :terminal mvn package
endfunction

command! MvnInstall call MvnInstall()
command! MvnPackage call MvnPackage()
