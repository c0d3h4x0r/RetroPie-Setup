#!/bin/sh

esdir="$(dirname $0)"

while true; do
    rm -f /tmp/es-restart /tmp/es-sysrestart /tmp/es-shutdown
    "$esdir/scripts/wifi-power"
    "$esdir/scripts/bgm-start"
    "$esdir/emulationstation" "$@" >$HOME/.emulationstation/es_output.txt 2>&1
    ret=$?
    "$esdir/scripts/bgm-stop"
    [ -f /tmp/es-restart ] && continue
    if [ -f /tmp/es-sysrestart ]; then
        rm -f /tmp/es-sysrestart
        sudo reboot
        break
    fi
    if [ -f /tmp/es-shutdown ]; then
        rm -f /tmp/es-shutdown
        sudo poweroff
        break
    fi
    break
done
exit $ret
