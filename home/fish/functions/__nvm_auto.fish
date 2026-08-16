function __nvm_auto --on-variable PWD --description 'Activate the Node version from the nearest .nvmrc, in pure fish'
    status is-command-substitution; and return

    set -l nvm_dir $NVM_DIR
    test -n "$nvm_dir"; or set nvm_dir "$HOME/.nvm"

    # Walk up from $PWD looking for the nearest .nvmrc
    set -l dir $PWD
    set -l file ""
    while test -n "$dir"
        if test -r "$dir/.nvmrc"
            set file "$dir/.nvmrc"
            break
        end
        set dir (string replace -r '/[^/]*$' '' -- $dir)
    end

    # No .nvmrc in scope: fall back to the default alias
    set -l bin
    if test -z "$file"
        set bin (__nvm_default_bin)
    else
        set bin (__nvm_resolve_spec (string trim <"$file"))
        if test -z "$bin"
            # Warn once per .nvmrc, not on every cd
            if test "$__nvm_warned" != "$file"
                set -g __nvm_warned $file
                echo "nvm: version demandée par $file non installée — lance `nvm install`" >&2
            end
            return
        end
        set -g __nvm_warned ""
    end

    test -n "$bin"; or return
    test "$bin" = "$__nvm_current_bin"; and return

    # Drop every nvm bin dir from PATH, then prepend the one we want
    set -l cleaned
    for p in $PATH
        string match -q -- "$nvm_dir/versions/node/*" $p; or set -a cleaned $p
    end
    set -gx PATH $bin $cleaned
    set -g __nvm_current_bin $bin
end
