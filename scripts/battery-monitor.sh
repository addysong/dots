#!/usr/bin/env bash

command -v upower >/dev/null 2>&1 || exit 127

upower_battery_device="$(upower -e | grep -m1 battery_BAT)"
battery_directory="$(echo /sys/class/power_supply/BAT*)"

notified_charging=0

notified_25=0
notified_15=0
notified_5=0

get-charging-icon() {
	local capacity=$1
	if ((capacity <= 5)); then
		echo battery-empty-charging-symbolic
	elif ((capacity <= 15)); then
		echo battery-caution-charging-symbolic
	elif ((capacity < 50)); then
		echo battery-low-charging-symbolic
	else
		echo battery-good-charging-symbolic
	fi
}

update() {
	local capacity="$(cat "$battery_directory/capacity")"
	local status="$(cat "$battery_directory/status")"

	if [[ "$status" != "Discharging" ]]; then
		notified_25=0
		notified_15=0
		notified_5=0

		if [[ "$status" = "Charging" ]] && ((notified_charging == 0)); then
			local charging_icon=$(get-charging-icon "$capacity")
			notified_charging=1
			notify-send \
				-h string:fgcolor:#a6d189f0 \
				-h string:frcolor:#a6d189f0 \
				-i "$charging_icon" \
				"Charging ($capacity%)"
		fi

		return 0
	fi

	notified_charging=0

	if ((capacity <= 5)) && ((notified_5 == 0)); then
		notified_25=1
		notified_15=1
		notified_5=1
		notify-send \
			-h string:fgcolor:#e78284f0 \
			-h string:frcolor:#e78284f0 \
			-u critical \
			-i battery-empty-symbolic \
			"Very low battery ($capacity%)" \
			"Going to sleep soon"
	elif ((capacity <= 15)) && ((notified_15 == 0)); then
		notified_25=1
		notified_15=1
		notify-send \
			-h string:fgcolor:#e78284f0 \
			-h string:frcolor:#e78284f0 \
			-u critical \
			-i battery-caution-symbolic \
			"Low battery ($capacity%)"
	elif ((capacity <= 25)) && ((notified_25 == 0)); then
		notified_25=1
		notify-send \
			-h string:fgcolor:#ef9f76f0 \
			-h string:frcolor:#ef9f76f0 \
			-i battery-low-symbolic \
			"Low battery ($capacity%)"
	fi
}

update

upower --monitor-detail | while IFS= read -r line; do
	if [[ "$line" == *"$upower_battery_device"* ]]; then
		update
	fi
done
