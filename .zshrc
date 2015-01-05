# Path!
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:$HOME/.rvm/bin:$PATH

# Oh, my ZSH!
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="citelao"

plugins=(git brew osx zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# vim, Please!
export EDITOR=vim
export VISUAL=vim
export GIT_EDITOR=vim
export SVN_EDITOR=vim

export NVM_DIR="/Users/citelao/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm