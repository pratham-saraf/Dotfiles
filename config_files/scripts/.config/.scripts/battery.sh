#!/bin/bash

# Function to send notification and play alert sound
send_notification() {
    notify-send "$1" "$2"
    
    # Check if the system is muted
    is_muted=$(amixer get Master | grep -o '\[off\]')
    
    if [ -n "$is_muted" ]; then
        # System is muted, so unmute and set volume to 100%
        amixer -q sset Master unmute
        amixer -q sset Master 100%
        paplay ./battery-notif-sound.mp3
        # Mute the system again after playing the sound
        amixer -q sset Master mute
    else
        # System is not muted, play at current volume
        paplay /home/psaraf/.config/.scripts/battery-notif-sound.mp3
    fi
}

notify-send "Monitoring battery with audio!"

while true; do
   # Get battery percentage and status
   battery_status=$(acpi -b)
   battery_percentage=$(echo "$battery_status" | awk '{print $4}' | tr -d ',%') 
   charging_status=$(echo "$battery_status" | awk '{print $3}')

   # Check if battery is low and discharging
   if [[ $battery_percentage -le 30 && $charging_status != "Charging," ]]; then
       send_notification "Battery Low" "Plug in charger!"
   
   # Check if battery is full and charging
   elif [[ $battery_percentage -ge 80 && $charging_status == "Charging," ]]; then
       send_notification "Battery Full" "Unplug charger!"
   fi

   sleep 60 # Sleep for a short period to prevent excessive polling
done
