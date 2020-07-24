RetroPie-Setup (c0d3h4x0r fork)
===============================
This public fork of RetroPie-Setup is for users who need fixes *now* for annoying problems/shortcomings that the mainline RetroPie maintainer isn't willing to do anything about or accept fixes for.

The main advantages this fork offers are:

* Rewritten Bluetooth configurator for more reliable device scanning, pairing, connecting, and display.  It uses `bluetoothctl` under the hood to do all scanning, pairing, connecting, trusting, etc.  It has been self-tested against a variety of Bluetooth devices, including PS3 sixaxis/DualShock controllers, and verified to work better with all of them.

* Better gamepad button mappings for the joy2key script used to drive the RetroPie-Setup and runcommand textual menus with a gamepad.  The changes in this fork make the gamepad button mappings match those used in EmulationStation, including using the L/R shoulder buttons for PageUp/PageDown.
  * **NOTE**: You'll need to run `retropie_setup.sh` and use its package manager to re-install the `runcommand` package from "prebuilt binaries" to get the runcommand dialog to pick up the fix.

* Added ability to `splashscreen` module to configure the playback volume of a video splashscreen.
  * **NOTE**: You'll need to run `retropie_setup.sh` and use its package manager to re-install the `splashscreen` package from "prebuilt binaries" to get the splashscreen to pick up this new setting.

* Greatly improved `joy2key` script used to drive the `retropie_setup.sh` and `runcommand` textual menus with a gamepad.  The changes in this fork make the gamepad control of these menus far more responsive and reliable.

How to install
--------------
```shell
cd ~/RetroPie-Setup
git remote add c0d3h4x0r https://github.com/c0d3h4x0r/RetroPie-Setup.git
git branch --set-upstream-to=c0d3h4x0r/master
git pull
```

General Usage
-------------

Shell script to setup the Raspberry Pi, Vero4K, ODroid-C1 or a PC running Ubuntu with many emulators and games, using EmulationStation as the graphical front end. Bootable pre-made images for the Raspberry Pi are available for those that want a ready to go system, downloadable from the releases section of GitHub or via our website at https://retropie.org.uk

This script is designed for use on Raspbian on the Raspberry Pi, OSMC on the Vero4K or Ubuntu on the ODroid-C1 or a PC.

To run the RetroPie Setup Script make sure that your APT repositories are up-to-date and that Git is installed:

```shell
sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get install git
```

Then you can download the latest RetroPie setup script with

```shell
cd
git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
```

The script is executed with 

```shell
cd RetroPie-Setup
sudo ./retropie_setup.sh
```

When you first run the script it may install some additional packages that are needed.

Binaries and Sources
--------------------

On the Raspberry Pi, RetroPie Setup offers the possibility to install from binaries or source. For other supported platforms only a source install is available. Installing from binary is recommended on a Raspberry Pi as building everything from source can take a long time.

For more information visit the blog at https://retropie.org.uk or the repository at https://github.com/RetroPie/RetroPie-Setup.

Wiki
----

You can find useful information about several components or for several frequently asked questions in the [wiki](https://github.com/RetroPie/RetroPie-Setup/wiki) of the RetroPie Script. If you think that there is something missing, you are invited to add it to the wiki.


Thanks
------

This script just simplifies the usage of the great works of many other people that enjoy the spirit of retrogaming. Many thanks go to them!
