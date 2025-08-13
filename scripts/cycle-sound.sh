#!/bin/bash

#!/usr/bin/env bash
set -euo pipefail

# Gather sink IDs
mapfile -t sinks < <(
  pw-dump | jq -r '.[]
    | select(.type=="PipeWire:Interface:Node" and .info.props."media.class"=="Audio/Sink")
    | .id'
)

# Current default sink id
default_sink=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | awk 'NR==1 { gsub(",","",$2); print $2 }')

# Fallback if default not found
next_sink="${sinks[0]}"

# Find index of default and pick the next (cyclic)
for i in "${!sinks[@]}"; do
  if [[ "${sinks[i]}" == "$default_sink" ]]; then
    next_sink="${sinks[ $(( (i+1) % ${#sinks[@]} )) ]}"
    break
  fi
done

wpctl set-default "$next_sink"
