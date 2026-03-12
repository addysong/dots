#
# ~/.bash_profile
#

if [[ -x /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/binbrew shellenv bash)"
end

[[ -f ~/.bashrc ]] && . ~/.bashrc
