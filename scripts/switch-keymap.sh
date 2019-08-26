#!/bin/bash
variant=$(setxkbmap -query | grep variant)
if [[ $variant == "" ]]
then
  setxkbmap -layout "us" -variant "colemak" -option "caps:escape" -option "altwin:swap_lalt_lwin"
else
  setxkbmap -variant "" -option ""
fi
