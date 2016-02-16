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
bindkey -v
bindkey "${terminfo[kcuu1]}" up-line-or-search # but with expected up/down arrow movement
bindkey "${terminfo[kcud1]}" down-line-or-search

export NVM_DIR="/Users/citelao/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

unalias gm

# added by travis gem
[ -f /Users/citelao/.travis/travis.sh ] && source /Users/citelao/.travis/travis.sh
