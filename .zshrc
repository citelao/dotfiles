# Path!
if [[ "$(uname)" == "Darwin" ]]; then
	export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:$HOME/.rvm/bin:$HOME/.composer/vendor/bin:$PATH
else
	export PATH=$HOME/.rbenv/bin:$PATH
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

if [[ -d "$ZSH" ]]; then
	source $ZSH/oh-my-zsh.sh
fi

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

if [[ "$(uname)" == "Linux" ]]; then
	eval "$(rbenv init -)"
fi

# Ignore errors with this.
unalias gm 2>/dev/null