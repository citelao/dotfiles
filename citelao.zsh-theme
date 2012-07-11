# Prompts!
local cmd_status="%(?,%{$fg[green]%},%{$fg[red]%}):%{$reset_color%}"

PROMPT='
%{$cmd_status%} %{$fg[blue]%}%~ %{$fg[green]%}(%n)
$%{$reset_color%} '

RPROMPT='$(git_prompt_info)%{$fg[cyan]%}@%m%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%} %{$fg[yellow]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*%{$fg[yellow]%}"