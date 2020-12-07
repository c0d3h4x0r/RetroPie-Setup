#!/usr/bin/env sh

if [ -z "$1" ]; then
    echo "USAGE: $0 <hostname-of-other-retropie>"
    exit 1
fi

rsync -rcKP $/home/pi/RetroPie/roms/ pi@$1:/home/pi/RetroPie/roms/
