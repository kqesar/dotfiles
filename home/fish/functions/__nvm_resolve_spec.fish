function __nvm_resolve_spec --description 'Resolve an .nvmrc spec (alias or partial version) to an installed bin dir'
    set -l nvm_dir $NVM_DIR
    test -n "$nvm_dir"; or set nvm_dir "$HOME/.nvm"

    set -l spec (string trim -- "$argv[1]")

    # "node" and "stable" mean "the newest installed version": match everything
    if contains -- "$spec" node stable
        set spec ""
    end

    # Follow the alias chain, e.g. lts/* -> lts/krypton -> v24.19.0
    set -l guard 0
    while test -r "$nvm_dir/alias/$spec"
        set guard (math $guard + 1)
        test $guard -gt 6; and break
        set spec (string trim <"$nvm_dir/alias/$spec")
    end

    # Match a possibly partial version against what is installed: 24 -> v24.19.0
    set -l prefix (string replace -r '^v?' 'v' -- "$spec")
    set -l match (
        for d in $nvm_dir/versions/node/$prefix*
            test -x "$d/bin/node"; and path basename $d
        end | sort -V | tail -1
    )

    test -n "$match"; or return 1
    echo "$nvm_dir/versions/node/$match/bin"
end
