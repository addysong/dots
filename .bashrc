#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Some aliases for getting nicer visuals for certain commands

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias tree='LC_COLLATE=C tree -F --dirsfirst'
alias clear='printf "\e[H\e[2J\e[3J"'

# Utility commands

alias battery='cat /sys/class/power_supply/BAT0/capacity'

alias randwall='./.config/hypr/scripts/random-wall.sh'

# Typos

alias xit='exit'

if command -v batman >/dev/null; then
	alias man='batman'
fi

# Prompt
__prompt_branch() {
	local branch
	branch=$(git branch --show-current 2>/dev/null)
	[[ -n $branch ]] && printf '[%s]' "$branch"
}

__prompt_status_color=$'\e[1;32m'
__prompt_set_status_color() {
	if (( $1 == 0 )); then
		__prompt_status_color=$'\e[1;32m'
	else
		__prompt_status_color=$'\e[1;31m'
	fi
}

PS1='\[\e[1;33m\]\u:\[\e[0m\]\[\e[1;36m\]\w\[\e[0m\]\[\e[1;35m\]$(__prompt_branch)\[\e[0m\]\n\[$__prompt_status_color\]\$\[\e[0m\] '

detach() {
	( nohup "$@" >/dev/null 2>&1 & )
}

bats() {
    BATS_RUN_SKIPPED=true command bats *.bats
}

# History
HISTCONTROL=ignoreboth
shopt -s histappend
PROMPT_COMMAND="__prompt_set_status_color \$?; history -a; history -c; history -r${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Bash Completion
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
	source /usr/share/bash-completion/bash_completion
fi

# Include additional bin directories on PATH
prepend_path() {
	case ":${PATH}:" in
		*:"$1":*) ;;
		*) PATH="$1:$PATH" ;;
	esac
}
prepend_path "$HOME/bin"
prepend_path "$HOME/.local/bin"
prepend_path "$HOME/scripts"
prepend_path "$HOME/go/bin"
export PATH

export npm_config_prefix=$HOME/.local

export EDITOR=nvim
export SUDO_EDITOR=nvim

export FZF_DEFAULT_OPTS=" \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

command -v zoxide >/dev/null && eval "$(zoxide init bash)"
command -v direnv >/dev/null && eval "$(direnv hook bash)"
command -v luarocks >/dev/null && eval "$(luarocks path)"

command -v brew >/dev/null && export PATH="$(brew --prefix python)/libexec/bin:$PATH"

# Automatically source python venv in tmux if it has already been started
if [[ -n "$VIRTUAL_ENV" ]]; then
	source "$VIRTUAL_ENV/bin/activate"
fi

# Disable ctrl+s "freezing" the terminal
stty -ixon

# Machine-specific config file
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
