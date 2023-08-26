#!/bin/bash

# Get battery status and level
battery_status=$(cat /sys/class/power_supply/BAT1/status)
battery_level=$(acpi -b | grep -Eo "[0-9]+%" | cut -d '%' -f1)

# Check if battery level is less than 10%
if [ $battery_level -lt 10 ]; then
    # Check if system is not charging
    if [ "$battery_status" != "Charging" ]; then
        # Send notification to plug in charger
        dunstify -u critical "Low Battery" "Battery level is at ${battery_level}%. Please plug in the charger."
    fi
# Check if battery level is greater than or equal to 90%
elif [ $battery_level -ge 90 ]; then
    # Check if system is charging
    if [ "$battery_status" == "Charging" ]; then
        # Send notification to unplug charger
        dunstify -u normal "High Battery" "Battery level is at ${battery_level}%. Please unplug the charger."
    fi
fi

