#!/bin/bash

# Check if a Bluetooth device is connected
bluetooth_connected=$(bluetoothctl info | grep "Connected: yes")

# Check if an earphone is connected to the audio jack
audio_jack_connected=$(amixer -c 0 cget numid=19 | grep "value")

# Check if any device is connected
if [[ $bluetooth_connected ]]; then
    echo "Bluetooth headphone is connected."
elif [[ $audio_jack_connected ]]; then
    echo "Earphone is connected to the audio jack."
else
    echo "No headphone or earphone is connected."
fi

