# Path!
if [[ "$(uname)" == "Darwin" ]]; then
	export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:$HOME/.rvm/bin:$PATH
else
	# Don't change WSL path. We'll prob want to do this later
fi

# Oh, my ZSH!
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="citelao"

COMPLETION_WAITING_DOTS="true"

if [[ "$(uname)" == "Darwin" ]]; then
	plugins=(git brew osx zsh-syntax-highlighting)
else
	plugins=(git zsh-syntax-highlighting)
fi
source $ZSH/oh-my-zsh.sh

# vim, Please!
export EDITOR=vim
export VISUAL=vim
export GIT_EDITOR=vim
export SVN_EDITOR=vim
bindkey -v
bindkey "${terminfo[kcuu1]}" up-line-or-search # but with expected up/down arrow movement
bindkey "${terminfo[kcud1]}" down-line-or-search
bindkey '^[[A' up-line-or-search 
bindkey '^[[B' down-line-or-search

if [[ "$(uname)" == "Darwin" ]]; then
	export NVM_DIR="/Users/citelao/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
fi

unalias gm

# added by travis gem
[ -f /Users/citelao/.travis/travis.sh ] && source /Users/citelao/.travis/travis.sh
