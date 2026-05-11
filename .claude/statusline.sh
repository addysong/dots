#!/bin/bash

# Read input from Claude Code and make grabbing fields convenient
input=$(cat)

# Use these helpers to parse from fields instead of calling jq directly. Use
# fetch_int for any fields that are supposed to return integers to avoid
# floating-point weirdness with some numbers, or to round the field to a whole
# number.
# There should be NO NEED to call jq outside of these "fetch_..." functions.
fetch() { echo "$input" | jq -r ".$1"; }
fetch_int() { echo "$input" | jq "(.$1 // 0) | round"; }

RESET=$'\033[0m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
BG_BLACK=$'\033[40m'
BG_RESET=$'\033[49m'

format_tokens() {
	tokens=$1

	if [ "$tokens" -ge 1000000 ]; then
		rounded=$(( (tokens + 500000) / 1000000 ))
		echo "${rounded}m"
	elif [ "$tokens" -ge 1000 ]; then
		rounded=$(( (tokens + 500) / 1000 ))
		echo "${rounded}k"
	else
		echo "$tokens"
	fi
}

make_bar() {
	percentage=$1
	length=$2

	filled=$(( (percentage * length * 8 + 50) / 100 ))

	bar=""
	for (( i = 0; i < length; i++ )); do
		case 1 in
			$(( filled >= 8 ))) bar="${bar}█"; filled=$(( filled - 8 )) ;;
			$(( filled >= 7 ))) bar="${bar}▉"; filled=$(( filled - 7 )) ;;
			$(( filled >= 6 ))) bar="${bar}▊"; filled=$(( filled - 6 )) ;;
			$(( filled >= 5 ))) bar="${bar}▋"; filled=$(( filled - 5 )) ;;
			$(( filled >= 4 ))) bar="${bar}▌"; filled=$(( filled - 4 )) ;;
			$(( filled >= 3 ))) bar="${bar}▍"; filled=$(( filled - 3 )) ;;
			$(( filled >= 2 ))) bar="${bar}▎"; filled=$(( filled - 2 )) ;;
			$(( filled >= 1 ))) bar="${bar}▏"; filled=$(( filled - 1 )) ;;
			*)                  bar="${bar} " ;;
		esac
	done

	echo "${BG_BLACK}${bar}${BG_RESET}"
}

model=$(fetch model.display_name)
context_window_size=$(fetch_int context_window.context_window_size)

# Determine context bar width: 6 chars for 1M context window, 3 otherwise
if [ "$context_window_size" -ge 1000000 ]; then
	bar_width=6
else
	bar_width=3
fi

context_percent=$(fetch_int context_window.used_percentage)
context_bar=$(make_bar "$context_percent" "$bar_width")

five_hour_usage=$(fetch_int rate_limits.five_hour.used_percentage)
five_hour_resets_at=$(fetch rate_limits.five_hour.resets_at)

# Compute time remaining until 5-hour window resets
if [ -n "$five_hour_resets_at" ] && [ "$five_hour_resets_at" != "null" ]; then
	now=$(date +%s)
	secs_remaining=$(( five_hour_resets_at - now ))
	if [ "$secs_remaining" -le 0 ]; then
		usage_reset_label="(resets now)"
	else
		hrs=$(( secs_remaining / 3600 ))
		mins=$(( (secs_remaining % 3600) / 60 ))
		if [ "$hrs" -gt 0 ]; then
			usage_reset_label="(${hrs}h${mins}m)"
		else
			usage_reset_label="(${mins}m)"
		fi
	fi
else
	usage_reset_label=""
fi

# Git branch: full colored segment (icon + name + trailing separator), or empty
git_branch=$(git -C "$(fetch workspace.current_dir)" --no-optional-locks branch --show-current 2>/dev/null)
if [ -n "$git_branch" ]; then
	branch_label="${GREEN}󰘬 ${git_branch}${RESET}  "
else
	branch_label=""
fi

# Reasoning effort level (shown in parentheses after model name)
effort_level=$(fetch effort.level)
if [ -n "$effort_level" ] && [ "$effort_level" != "null" ]; then
	model_label="${model} (${effort_level})"
else
	model_label="${model}"
fi

# Build the status line: branch_label is either a full colored segment or empty
printf "%s" \
	"${branch_label}" \
	"${YELLOW} ctx:${context_percent}% ${context_bar}${RESET}  " \
	"${BLUE}󰓅 usage:${five_hour_usage}% ${usage_reset_label}${RESET}  " \
	"${RED}󰚩 ${model_label}${RESET}" \
	$'\n'

