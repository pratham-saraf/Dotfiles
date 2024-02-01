#!/bin/bash

notify-send "Monitoring battery!"

while true; do
   # Get battery percentage and status
   battery_status=$(acpi -b)
   battery_percentage=$(echo "$battery_status" | awk '{print $4}' | tr -d ',%') 
   charging_status=$(echo "$battery_status" | awk '{print $3}')

   # Check if battery is low and discharging
   if [[ $battery_percentage -le 30 && $charging_status != "Charging," ]]; then
       notify-send "Battery Low" "Plug in charger!" # Send notification
   
   # Check if battery is full and charging
   elif [[ $battery_percentage -ge 80 && $charging_status == "Charging," ]]; then
       notify-send "Battery Full" "Unplug charger!" # Send notification
   fi

   sleep 60 # Sleep for a short period to prevent excessive polling
done
