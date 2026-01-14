# Prompts!
function statusicon {
	if [[ $EUID -eq 0 ]]; then
		echo -n "!"
	else
		if [[ -n "$SSH_CLIENT" ]]; then
			echo -n "✈"
		else
			echo -n ":"
		fi
	fi
}

# https://zsh.sourceforge.io/Doc/Release/Functions.html
function beep_if_last_command_slow {
	# https://askubuntu.com/a/407761
	local lastCommand=$(fc -l -D | tail -n1)
	local lastCommandId=$(echo $lastCommand | awk '{print $1}')
	local seconds=$(echo $lastCommand | awk '{print $2}' | awk -F: '{ print ($1 * 60) + $2 }')

	# If `-ne`: beep_if_last_command_slow:6: bad math expression: operator expected at `0' sometimes.
	if [[ $seconds -gt 1 && $lastCommandId != $BESTO_LAST_COMMAND_ID ]]; then
		# Play a nice sound! & remember that we did so for this command.
		(afplay /System/Library/Sounds/Frog.aiff -q 1 &) > /dev/null
		export BESTO_LAST_COMMAND_ID="$lastCommandId"
	fi
}

local cmd_status="%(?,%{$fg[green]%},%{$fg[red]%})$(statusicon)%{$reset_color%}"

precmd() {
	beep_if_last_command_slow
}

PROMPT='
%{$cmd_status%} %{$fg[blue]%}%~ %{$fg[white]%}(%{$fg[green]%}%n%{$fg[white]%})
%{$fg[green]%}$%{$reset_color%} '

# RVM rprompt
#RPROMPT='$(git_prompt_info)%{$fg[white]%}$(~/.rvm/bin/rvm-prompt)%{$reset_color%} '

# Otherwise rprompt
RPROMPT='$(git_prompt_info)%{$reset_color%} '

SPROMPT="zsh: correct %R to %r? 
%{$fg[green]%}[Y]urp %{$fg[grey]%}/ %{$fg[yellow]%}[N]urp %{$fg[grey]%}/ %{$fg[blue]%}[E]dit %{$fg[grey]%}/ %{$fg[red]%}[A]bort: %{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[yellow]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg[yellow]%}]%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}✸"

# LSCOLORS!
# From clean theme
export LSCOLORS="Gxfxcxdxbxegedabagacad"
export LS_COLORS='no=00:fi=00:di=01;34:ln=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=00;32:*.cmd=00;32:*.exe=01;32:*.com=01;32:*.bat=01;32:*.btm=01;32:*.dll=01;32:*.tar=00;31:*.tbz=00;31:*.tgz=00;31:*.rpm=00;31:*.deb=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.zip=00;31:*.zoo=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.tb2=00;31:*.tz2=00;31:*.tbz2=00;31:*.avi=01;35:*.bmp=01;35:*.fli=01;35:*.gif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mng=01;35:*.mov=01;35:*.mpg=01;35:*.pcx=01;35:*.pbm=01;35:*.pgm=01;35:*.png=01;35:*.ppm=01;35:*.tga=01;35:*.tif=01;35:*.xbm=01;35:*.xpm=01;35:*.dl=01;35:*.gl=01;35:*.wmv=01;35:*.aiff=00;32:*.au=00;32:*.mid=00;32:*.mp3=00;32:*.ogg=00;32:*.voc=00;32:*.wav=00;32:'

alias ls='ls -FGA'
alias e='open -a "Sublime Text 2"'
