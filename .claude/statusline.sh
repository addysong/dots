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

context_percent=$(fetch_int context_window.used_percentage)
context_bar=$(make_bar "$context_percent" 8)

rate_percent=$(fetch_int rate_limits.five_hour.used_percentage)
rate_bar=$(make_bar "$rate_percent" 8)

echo "${RED}${model} " \
	"${YELLOW}${context_percent}% ${context_bar} " \
	"${BLUE}${rate_percent}% ${rate_bar} " \
	"${RESET}"

