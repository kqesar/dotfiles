function nvm --description 'Node Version Manager (nvm-sh/nvm) bridged into fish via bass'
    if not test -s "$NVM_DIR/nvm.sh"
        echo "nvm: $NVM_DIR/nvm.sh introuvable" >&2
        return 1
    end
    bass source "$NVM_DIR/nvm.sh" --no-use ';' nvm $argv
end
