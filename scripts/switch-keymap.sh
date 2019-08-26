#!/bin/bash
variant=$(setxkbmap -query | grep variant)
if [[ $variant == "" ]]
then
  setxkbmap -layout "us" -variant "colemak" -option "caps:escape"
else
  setxkbmap -variant "" -option ""
fi
