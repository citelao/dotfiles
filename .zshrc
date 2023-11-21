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

	# Python --user installs
	add_to_path $HOME/Library/Python/3.8/bin

	# # Homebrew Ruby (which has M1 correctly setup)
	# Nevermind.
	# add_to_path /opt/homebrew/opt/ruby/bin
	# add_to_path /opt/homebrew/lib/ruby/gems/3.0.0/bin
else
	add_to_path $HOME/.rbenv/bin
fi

# Oh, my ZSH!
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="citelao"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

if [[ "$(uname)" == "Darwin" ]]; then
	# zsh-syntax-highlighting
	plugins=(git brew osx)
else
	# zsh-syntax-highlighting
	plugins=(git)
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

	# Don't update before every install.
	export HOMEBREW_NO_AUTO_UPDATE=1
fi

if [[ "$(uname)" == "Linux" ]]; then
	eval "$(rbenv init -)"
fi

if [[ "$(uname)" == "Darwin" ]]; then
	eval "$(rbenv init -)"
fi

# Ignore errors with this.
unalias gm 2>/dev/null

# Stop updating stuff, Homebrew.
HOMEBREW_NO_AUTO_UPDATE=1