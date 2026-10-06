#!/usr/bin/env bash

# Read input from Claude Code and make grabbing fields convenient
input=$(cat)

# Make parsing fields easy. There should be no need to run jq outside of these
# two helpers
fetch() { echo "$input" | jq -r ".$1"; }
fetch_int() { echo "$input" | jq "(.$1 // 0) | round"; }

# Get style from tput instead of hardcoding escape sequences
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BG_BLACK=$(tput setab 0)
BG_RESET=$(tput op)

# Format a large number with a suffix and up to one decimal place when useful
format_number() {
	local number=$1
	local divisor
	local suffix

	if ((number >= 1000000)); then
		divisor=1000000
		suffix='M'
	elif ((number >= 1000)); then
		divisor=1000
		suffix='K'
	else
		divisor=1
		suffix=''
	fi

	# Bash math is integer-only, so count in tenths of the unit (rounded),
	# then split that into the whole part and the one decimal digit
	local tenths=$(( (number * 10 + divisor / 2) / divisor ))
	local whole=$(( tenths / 10 ))
	local decimal=$(( tenths % 10 ))

	if (( decimal == 0  || whole >= 100 )); then
		whole=$(( (number + divisor / 2) / divisor ))
		printf '%d%s\n' "$whole" "$suffix"
	else
		printf '%d.%d%s\n' "$whole" "$decimal" "$suffix"
	fi
}

# Format the time remaining until a Unix epoch time, rounded down to the
# largest whole unit, e.g. 2d, 3h, 45m. Prints nothing and fails if the time
# has already passed
format_time_until() {
	local target_time=$1
	local seconds_left=$(( target_time - EPOCHSECONDS ))

	if ((seconds_left <= 0)); then
		return 1
	fi

	local minute=60
	local hour=$(( 60 * minute ))
	local day=$(( 24 * hour ))

	if ((seconds_left >= day)); then
		printf '%dd\n' "$(( seconds_left / day ))"
	elif ((seconds_left >= hour)); then
		printf '%dh\n' "$(( seconds_left / hour ))"
	else
		printf '%dm\n' "$(( seconds_left / minute ))"
	fi
}

status_top=()
status_bottom=()

model=$(fetch model.display_name)
context_window_size=$(fetch_int context_window.context_window_size)

# Reasoning effort level (shown in parentheses after model name)
effort_level=$(fetch effort.level)
model_label=$model
if [[ -n $effort_level && $effort_level != 'null' ]]; then
	model_label+=" ($effort_level)"
fi

project_dir=$(fetch workspace.project_dir)
project_dir=${project_dir##*/}
status_top+=("$CYAN$project_dir$RESET")

current_dir=$(fetch workspace.current_dir)
git_branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)
[[ -n $git_branch ]] && status_top+=("$MAGENTA[$git_branch]$RESET")

# Context usage, e.g. 12.3%/1M. Calculated from the tokens in the context
# rather than used_percentage, which is only a whole number
context_tokens=$(( $(fetch_int context_window.current_usage.input_tokens)
	+ $(fetch_int context_window.current_usage.cache_creation_input_tokens)
	+ $(fetch_int context_window.current_usage.cache_read_input_tokens) ))

# Bash math is integer-only, so count in tenths of a percent (rounded down),
# then split that into the whole part and the one decimal digit
context_tenths=0
if ((context_window_size > 0)); then
	context_tenths=$(( context_tokens * 1000 / context_window_size ))
fi
context_percent="$(( context_tenths / 10 )).$(( context_tenths % 10 ))"
window_size=$(format_number "$context_window_size")
status_bottom+=("${YELLOW}$context_percent%/$window_size$RESET")

# Rate limits, e.g. 42%(2h) 17%(3d). Claude Code drops a window from the input
# once it resets, so each window is shown only while it's present, and the
# time until reset only while that time is still in the future
rate_limits=()
for window in five_hour seven_day; do
	used=$(fetch "rate_limits.$window.used_percentage")
	if [[ $used == 'null' ]]; then
		continue
	fi

	label="$used%"
	resets_at=$(fetch_int "rate_limits.$window.resets_at")
	if reset=$(format_time_until "$resets_at"); then
		label+="($reset)"
	fi
	rate_limits+=("$label")
done
if ((${#rate_limits[@]} > 0)); then
	status_bottom+=("$BLUE${rate_limits[*]}$RESET")
fi

# Model with its effort level and fast mode, e.g. Opus 5.5 (medium, fast)
model=$(fetch model.display_name)
effort=$(fetch effort.level)
fast_mode=$(fetch fast_mode)

model_details=''
if [[ $effort != 'null' ]]; then
	model_details=$effort
fi
if [[ $fast_mode == 'true' ]]; then
	if [[ -n $model_details ]]; then
		model_details+=', '
	fi
	model_details+='fast'
fi

model_label=$model
if [[ -n $model_details ]]; then
	model_label+=" ($model_details)"
fi
status_bottom+=("$MAGENTA$model_label$RESET")

printf '%s\n%s' "${status_top[*]}" "${status_bottom[*]}"
