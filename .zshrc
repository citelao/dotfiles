# RVM!
# [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" 

# Path!
#export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:$HOME/.rvm/bin
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin

# Oh, my ZSH!
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="citelao"

plugins=(git)
source $ZSH/oh-my-zsh.sh

# Chocolat, Please!
export EDITOR=vim
export VISUAL=vim
export GIT_EDITOR=vim
export SVN_EDITOR=vim
