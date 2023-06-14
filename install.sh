#!/bin/bash
SOURCE_DOTFILE="source ~/dotfiles/.bashrc"
PROFILE="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
  PROFILE="$HOME/.zshrc"
fi
GREP_DOTFILE_BASHRC=$(grep -c "$SOURCE_DOTFILE" "$PROFILE")
if [ "$GREP_DOTFILE_BASHRC" -eq 0 ]; then
  echo "$SOURCE_DOTFILE" >> "$PROFILE"
  source "$PROFILE"
  echo 'dotfiles/.bashrc is sourced now'
fi

if [ ! -f "$HOME/.tmux.conf" ]; then
  echo 'Create symbolic link for tmux.conf'
  ln -vs "$HOME/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
  echo ''
fi

if [ ! -d "$HOME/.oh-my-bash/themes/mytheme" ]; then
  echo 'Create symbolic link for custom theme for oh-my-bash'
  ln -vs "$HOME/dotfiles/mytheme/" "$HOME/.oh-my-bash/themes/"
  echo ''
fi

if [ ! -d "$HOME/.config/lvim" ]; then
  echo 'Create symbolic link for config for lunarvim'
  ln -vs "$HOME/dotfiles/lvim/" "$HOME/.config/"
  echo ''
fi

if [ ! -f "$HOME/.gitignore" ]; then
  echo 'Create symbolic link for gitignore'
  ln -vs "$HOME/dotfiles/.gitignore" "$HOME/.gitignore" 
  echo ''
fi
