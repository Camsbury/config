#!/usr/bin/env bash

# Get the desired brightness level from the command line argument
brightness_level=$1

# Get the names of all connected outputs
outputs=$(xrandr | grep " connected" | awk '{print $1}')

# Loop over the outputs and set each one to the desired brightness level
for output in $outputs; do
  xrandr --output $output --brightness $brightness_level
done
