# Installed as ~/.config/fish/conf.d/dotfiles.fish
#
# fish sources every conf.d/*.fish on its own, so config.fish never has to be
# touched — nothing of the user's is edited to install the hook, and removing
# this one file uninstalls it completely.
#
# conf.d also runs for non-interactive fish (`fish -c ...`), hence the guard.
# `exit` is deliberately not used here: in a sourced file it would terminate
# the shell itself rather than just this snippet.

if status is-interactive
    set -gx DOTFILES_DIR $HOME/dotfiles
    if test -f $DOTFILES_DIR/shell/hook.sh
        sh $DOTFILES_DIR/shell/hook.sh
    end
end
