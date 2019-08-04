#!/bin/bash

default_sink=$(pacmd list-sinks | awk '$1 == "*" && $2 == "index:" {print $3}')
sinks=$(pacmd list-sinks | sed 's|*||' | awk '$1 == "index:" {print $2}')
cycle_sink=1
count=0
for current_sink in $sinks; do
  if [ $cycle_sink == 1 ]; then
    next_sink=$current_sink
    cycle_sink=0
  fi
  if [ $current_sink == $default_sink ]; then
    cycle_sink=1
  fi
  count=$((count+1))
done
pacmd "set-default-sink $next_sink"

sink_inputs=$(pacmd list-sink-inputs | awk '$1 == "index:" {print $2}')
for sink_input in $sink_inputs; do
  pacmd move-sink-input $sink_input $next_sink
done
