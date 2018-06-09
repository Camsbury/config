# check remaining battery
percentage=`upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "percentage:" \
  | sed -r "s/\s*\S+\s+(.*)$/\1/"`
notify-send "Battery is at $percentage."
