#!/bin/bash
# Retrieve video lengths and names, printing them
find $1 -name "*.MP4" -printf "%f\n" | sort
mediainfo $1/*.MP4 | grep mdhd_Duration | grep -o "[0-9]*" | sort -nr
