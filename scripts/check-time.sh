# check the time
time=`timedatectl | grep "Local" | sed -r "s/.*time: (.*)/\1/"`
notify-send "$time"
