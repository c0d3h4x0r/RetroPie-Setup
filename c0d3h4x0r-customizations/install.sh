#!/usr/bin/env bash

COPY_OPTIONS='-b --no-preserve=ownership -r --suffix=.bak'

#sudo cp $COPY_OPTIONS ./boot/* /boot/
#sudo cp $COPY_OPTIONS ./etc/* /etc/
#cp $COPY_OPTIONS ./home/pi/* /home/pi/
#sudo cp $COPY_OPTIONS ./opt/* /opt/
#sudo chown -R pi:pi /opt/retropie/configs
#pushd /opt/retropie/supplementary/emulationstation/scripts > /dev/null
#sudo chmod 4751 ./bgm-player ./bgm-start ./bgm-stop
#sudo chgrp pi ./bgm-player ./bgm-start ./bgm-stop
#popd > /dev/null
#sudo apt-get install -y mpg123  # for bgm-player
#sudo apt-get install -y bc  # for hw_status

# set cmdline for silent boot
sudo sed 's/console=tty1/console=tty3/g; s/logo\.nologo//g; s/vt\.global_cursor_default=0//g; s/  / /g; s/$/logo\.nologo vt\.global_cursor_default=0/g' /boot/cmdline.txt

echo "Remember to run argoneone-install and argonone-config to make fan always run if you are using an Argon ONE case."
