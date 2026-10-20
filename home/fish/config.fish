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

# --- pnpm (standalone, outside Node) --------------------------------------
# Installed by get.pnpm.io's script rather than through Corepack, which Node no
# longer ships from 25.0.0. Living outside any Node version, it survives Node
# upgrades; inside a project it switches itself to the version `packageManager`
# pins. __nvm_auto below still prepends the active Node's bin directory, so on
# a Node where `corepack enable` was once run, that shim shadows this pnpm.
# Guarded: the other machine may not have it installed.
if test -d "$HOME/.local/share/pnpm/bin"
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    fish_add_path -g -p "$PNPM_HOME/bin"
end

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

# --- ssh agent ------------------------------------------------------------
# Keys live in the systemd user agent. ssh itself reaches it through
# ~/.ssh/config (IdentityAgent), so this export is for the tools that talk to
# the agent directly instead of going through ssh. Guarded, because a machine
# without that unit must get no variable rather than a dangling path.
if test -S "$XDG_RUNTIME_DIR/ssh-agent.socket"
    set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
end

# --- machine-local overrides ---------------------------------------------
# Everything specific to THIS machine goes here. Never versioned, so one
# shared config.fish serves both machines without any templating.
if test -f $HOME/.config/dotfiles/local.fish
    source $HOME/.config/dotfiles/local.fish
end
