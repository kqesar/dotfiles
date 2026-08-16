# fish — shared across machines.
#
# The dotfiles update check is NOT here: it lives in conf.d/dotfiles.fish,
# which fish sources on its own. Keeping it out of this file means installing
# or removing the hook never edits the config you actually maintain.

# Distro-provided config. Guarded, because the other machine may not be
# CachyOS: a missing file must degrade the shell, not break it.
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# --- nvm (nvm-sh/nvm, bridged into fish by the functions/ + bass) ---
set -gx NVM_DIR "$HOME/.nvm"

# Activates the Node version from the nearest .nvmrc, falling back to the
# `default` alias, and recomputes on every cd. Resolved in pure fish: no bash
# is spawned at shell startup.
#
# The explicit call is required to arm the `--on-variable PWD` handler —
# fish's lazy function loading would never trigger it on its own.
if functions -q __nvm_auto
    __nvm_auto
end

# --- machine-local overrides ---------------------------------------------
# Everything specific to THIS machine goes here. Never versioned, so one
# shared config.fish serves both machines without any templating.
if test -f $HOME/.config/dotfiles/local.fish
    source $HOME/.config/dotfiles/local.fish
end
