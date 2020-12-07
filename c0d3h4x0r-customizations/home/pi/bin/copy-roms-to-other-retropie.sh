#!/usr/bin/env sh

if [ -z "$1" ]; then
    echo "USAGE: $0 <hostname-of-other-retropie>"
    exit 1
fi

for dir in $(find /home/pi/RetroPie/roms/* -maxdepth 0 -type d ); do
    rsync -rP $dir/* pi@$1:$dir/
done
