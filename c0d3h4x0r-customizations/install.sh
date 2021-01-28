#!/usr/bin/env bash

set -e

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run using 'sudo'."
    exit 1
fi

SCRIPT_DIR="$(dirname "$0")"
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"

COPY_OPTIONS="--no-preserve=ownership -r"

cp $COPY_OPTIONS $SCRIPT_DIR/boot /
cp $COPY_OPTIONS $SCRIPT_DIR/etc /
sudo -u $USER cp $COPY_OPTIONS $SCRIPT_DIR/home/pi /home/
cp $COPY_OPTIONS $SCRIPT_DIR/root /

cp $COPY_OPTIONS $SCRIPT_DIR/opt /
chown -R pi:pi /opt/retropie/configs

pushd /opt/retropie/supplementary/emulationstation/scripts > /dev/null
chgrp pi ./bgm-player ./bgm-start ./bgm-stop
chmod 2654 ./bgm-player ./bgm-start ./bgm-stop
popd > /dev/null

apt-get install -y mpg123  # for bgm-player
apt-get install -y bc  # for hw_status

# set cmdline for silent boot
sed --in-place 's/ quiet//g; s/$/ quiet/g' /boot/cmdline.txt

# ensure CPU governor is always set to performance
[ -e /etc/init.d/raspi-config ] && rm /etc/init.d/raspi-config
sed -z -i -E 's/raspi-config //g; s/raspi-config: [^\n]*\n//g' .depend.boot
sed -z -i -E 's/raspi-config //g; s/raspi-config: [^\n]*\n//g' .depend.start
SYS_CPU_GOVERNOR=/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
[ -e "$SYS_CPU_GOVERNOR" ] && echo "performance" > "$SYS_CPU_GOVERNOR"

echo "Remember to run argoneone-install and argonone-config if you are using an Argon ONE case."
