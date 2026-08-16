completions=(
  git
  composer
  ssh
  docker
  docker-compose
  nvm
  npm
  go
  tmux
  kubectl
  defaults
)
# Which plugins would you like to load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  bashmarks
  nvm
  npm
  kubectl
)


# User configuration
export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

export EDITOR='lvim'

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="$HOME/.ssh/rsa_id"

source "$HOME/dotfiles/.bash_aliases"
source "$HOME/dotfiles/.bash_export"
source "$HOME/dotfiles/z.sh" 

