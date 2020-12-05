#!/usr/bin/env sh

if [ ! -d "./boot.$1" ]; then
    echo "USAGE: $0 <rpi3bplus|rpi4>"
    exit 1
fi

COPY_OPTIONS='-b --no-preserve=ownership -r --suffix=.bak'

sudo cp $COPY_OPTIONS "./boot.$1"/* /boot/
sudo cp $COPY_OPTIONS ./etc/* /etc/
cp $COPY_OPTIONS ./home/pi/* /home/pi/
sudo cp $COPY_OPTIONS ./opt/* /opt/
sudo chown -R pi:pi /opt/retropie/configs/all/emulationstation
sudo apt-get install -y mpg123
