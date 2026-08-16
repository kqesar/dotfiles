alias vimrc='lvim ~/.vimrc'
alias nvimconfig='lvim ~/.config/nvim/init.lua'
alias bashrc='lvim ~/.bashrc && source ~/.bashrc'
alias bashalias='lvim ~/.bash_aliases && source ~/.bash_aliases'
alias sourcebash='source ~/.bashrc'
alias grep='grep --color'
alias cp='cp -v'
alias ls='ls --color'
alias mkdir='mkdir -pv'
alias dotfiles='cd ~/dotfiles'
alias lg='lazygit'
alias lv='lvim'
alias t='tmux'
alias c='clear'

#alias to install the last version of lunarvim (nightlybuild on master)
alias installLunarVim='bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)'

#function to update neovim with nightly reliease
function updateNeovim () {
    cd $HOME
    wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz
    rm -Rf nvim
    tar -xvf nvim-linux64.tar.gz
    mv  nvim-linux64 nvim
    rm -Rf nvim-linux64.tar.gz
    cd -
}
