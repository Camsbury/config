#!/usr/bin/env sh

charge_state=`upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep \
  "state:" | sed -r "s/\s*\S+\s+(.*)$/\1/"`
percentage=`upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep \
  "percentage:" | sed -r "s/\s*\S+\s+(.*)%$/\1/"`

if [ $charge_state == "discharging" ] && [ $percentage -lt 20 ];
then
  notify-send "Low battery: $percentage%"
fi
