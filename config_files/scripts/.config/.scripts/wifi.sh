#!/bin/bash


state=$(ip a | grep -m1 wlo1 | awk '{print $9}')

if [ "$state" == "DOWN" ];then
	$(nmcli r wifi on)
fi

