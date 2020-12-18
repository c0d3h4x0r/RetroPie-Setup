#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$0")"
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"

COPY_OPTIONS="--no-preserve=ownership -r"

sudo cp $COPY_OPTIONS $SCRIPT_DIR/boot /
sudo cp $COPY_OPTIONS $SCRIPT_DIR/etc /
cp $COPY_OPTIONS $SCRIPT_DIR/home /
sudo cp $COPY_OPTIONS $SCRIPT_DIR/root /

sudo cp $COPY_OPTIONS $SCRIPT_DIR/opt /
sudo chown -R pi:pi /opt/retropie/configs

pushd /opt/retropie/supplementary/emulationstation/scripts > /dev/null
sudo chgrp pi ./bgm-player ./bgm-start ./bgm-stop
sudo chmod 2654 ./bgm-player ./bgm-start ./bgm-stop
popd > /dev/null

sudo apt-get install -y mpg123  # for bgm-player
sudo apt-get install -y bc  # for hw_status

# set cmdline for silent boot
sudo sed --in-place 's/ quiet//g; s/$/ quiet/g' /boot/cmdline.txt

echo "Remember to run argoneone-install and argonone-config to make fan always run if you are using an Argon ONE case."
