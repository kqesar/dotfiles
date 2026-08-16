function __nvm_default_bin --description 'Resolve the nvm "default" alias to its bin directory, in pure fish'
    set -l nvm_dir $NVM_DIR
    test -n "$nvm_dir"; or set nvm_dir "$HOME/.nvm"

    # Follow the alias chain, e.g. default -> lts/* -> lts/krypton -> v24.19.0
    set -l target default
    for i in (seq 6)
        set -l file "$nvm_dir/alias/$target"
        test -r "$file"; or break
        set target (string trim <"$file")
    end

    string match -qr '^v\d+\.\d+\.\d+$' -- $target; or return 1
    set -l bin "$nvm_dir/versions/node/$target/bin"
    test -d "$bin"; or return 1
    echo $bin
end
