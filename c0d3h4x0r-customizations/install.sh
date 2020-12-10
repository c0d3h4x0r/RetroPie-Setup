#!/usr/bin/env sh

COPY_OPTIONS='-b --no-preserve=ownership -r --suffix=.bak'

sudo cp $COPY_OPTIONS ./boot/* /boot/
sudo cp $COPY_OPTIONS ./etc/* /etc/
cp $COPY_OPTIONS ./home/pi/* /home/pi/
sudo cp $COPY_OPTIONS ./opt/* /opt/
sudo chown -R pi:pi /opt/retropie/configs
sudo apt-get install -y mpg123 bc

echo "Now go modify /boot/config.txt to add/modify the parameters found in /boot/config.txt.silent-boot"
