RetroPie-Setup (c0d3h4x0r fork)
===============================
This public fork of RetroPie-Setup is for users who need fixes *now* for annoying problems/shortcomings that the mainline RetroPie maintainer isn't willing to do anything about or accept fixes for.

The main advantages this fork offers are:

* Rewritten Bluetooth configurator for more reliable device scanning, pairing, connecting, and display.  It uses `bluetoothctl` under the hood to do all scanning, pairing, connecting, trusting, etc.  It has been self-tested against a variety of Bluetooth devices, including PS3 sixaxis/DualShock controllers, and verified to work better with all of them.

* Better gamepad button mappings for the joy2key script used to drive the `retropie_setup.sh` and `runcommand` textual menus with a gamepad.  The changes in this fork make the gamepad button mappings match those used in EmulationStation, including using the L/R shoulder buttons for PageUp/PageDown.
  * **NOTE**: You'll need to run `retropie_setup.sh` and use its package manager to re-install the `runcommand` package from "prebuilt binaries" to get the runcommand dialog to pick up the fix.

* Added ability to `splashscreen` module to configure the playback volume of a video splashscreen.
  * **NOTE**: You'll need to run `retropie_setup.sh` and use its package manager to re-install the `splashscreen` package from "prebuilt binaries" to get the splashscreen to pick up this new setting.

* Greatly improved `joy2key` script used to drive the `retropie_setup.sh` and `runcommand` textual menus with a gamepad.  The changes in this fork make the gamepad control of these menus far more responsive and reliable.

How to install this fork
------------------------
```shell
cd ~/RetroPie-Setup
git remote add c0d3h4x0r https://github.com/c0d3h4x0r/RetroPie-Setup.git
git branch --set-upstream-to=c0d3h4x0r/master
git pull
```

Mainline documentation
----------------------
Please refer to the [mainline readme](https://githubcom/RetroPie/RetroPie-Setup.git).
