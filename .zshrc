# Path!
# add_to_path new/path/thing
function add_to_path()
{
	addition=$1

	if [[ -d "$addition" ]]; then
		export PATH=$addition:$PATH
	else
		echo "Skipping non-existent path '$addition'"
	fi
}

if [[ "$(uname)" == "Darwin" ]]; then
	# Original Homebrew path!
	# add_to_path /usr/local/bin

	add_to_path /usr/bin
	add_to_path /bin
	add_to_path /usr/sbin
	add_to_path /sbin

	# add_to_path /usr/X11/bin
	# add_to_path $HOME/.rvm/bin
	# add_to_path $HOME/.composer/vendor/bin

	# New Homebrew location!
	add_to_path /opt/homebrew/bin
else
	add_to_path $HOME/.rbenv/bin
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