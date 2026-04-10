#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Some aliases for getting nicer visuals for certain commands

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias clear='printf "\e[H\e[2J\e[3J"'

if command -v batman >/dev/null 2>&1; then
	alias man='batman'
fi

# Convenient aliases for commands I run frequently

alias hypredit='nvim ~/.config/hypr/hyprland.conf'

PS1='[\u@\h \W]\$ '

nnohup() {
    nohup "$@" >/dev/null >&1 &
}

bats() {
    BATS_RUN_SKIPPED=true command bats *.bats
}

# History
HISTCONTROL=ignoreboth
shopt -s histappend
PROMPT_COMMAND="history -a; history -c; history -r${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Bash Completion
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
	source /usr/share/bash-completion/bash_completion
fi

# Include additional bin directories on PATH
export PATH=$HOME/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/scripts:$PATH
export PATH=$HOME/go/bin:$PATH

export npm_config_prefix=$HOME/.local

export EDITOR=nvim
export SUDO_EDITOR=nvim

export FZF_DEFAULT_OPTS=" \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

eval "$(starship init bash)"
eval "$(zoxide init bash)"

# opencode
export PATH=/home/addys/.opencode/bin:$PATH

# Automatically source python venv in tmux if it has already been started
if [[ -n "$VIRTUAL_ENV" ]]; then
	source "$VIRTUAL_ENV/bin/activate"
fi
