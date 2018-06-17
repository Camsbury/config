# check the time
time=`timedatectl | grep "Local" | sed -r "s/^\s*(\S+\s+){4}(\S+)\s+\S+$/\2/"`
notify-send "$time"
