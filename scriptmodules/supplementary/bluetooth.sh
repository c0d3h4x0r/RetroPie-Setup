#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="bluetooth"
rp_module_desc="Configure Bluetooth devices"
rp_module_section="config"

function _is_keyboard_attached_bluetooth() {
    grep -qP --regexp='(?s)(?<=^H: Handlers=).*\bkbd(?=\b)' /proc/bus/input/devices
    return $?
}

function _is_joystick_attached_bluetooth() {
    grep -qP --regexp='(?s)(?<=^H: Handlers=).*\bjs[0-9]+(?=\b)' /proc/bus/input/devices
}

function _update_hook_bluetooth() {
    # fix config location
    [[ -f "$configdir/bluetooth.cfg" ]] && mv "$configdir/bluetooth.cfg" "$configdir/all/bluetooth.cfg"
    local mode="$(_get_connect_mode_bluetooth)"
    # if user has set bluetooth connect mode to boot or background, make sure we
    # have the latest dependencies and update systemd script
    if [[ "$mode" != "default" ]]; then
        # make sure dependencies are up to date
        ! hasPackage "bluez-tools" && depends_bluetooth
        connect_mode_set_bluetooth "$mode"
    fi
}

function _get_connect_mode_bluetooth() {
    # get bluetooth config
    iniConfig "=" '"' "$configdir/all/bluetooth.cfg"
    iniGet "connect_mode"
    if [[ -n "$ini_value" ]]; then
        echo "$ini_value"
    else
        echo "default"
    fi
}

function depends_bluetooth() {
    local depends=(bluetooth python-dbus python-gobject bluez-tools)
    if [[ "$__os_id" == "Raspbian" ]]; then
        depends+=(pi-bluetooth raspberrypi-sys-mods)
    fi
    getDepends "${depends[@]}"
}

function _bluetoothctl_cmds_bluetooth() {
    local -n _commands=$1
    local -n _responses=$2
    local _commands=("" "${_commands[@]}")
    local _responses=("Agent registered" "${_responses[@]}")

    local capability
    if _is_keyboard_attached_bluetooth; then
        capability='KeyboardDisplay'
    elif _is_joystick_attached_bluetooth; then
        capability='DisplayYesNo'
    else
        capability='DisplayOnly'
    fi

    # create a named pipe & fd for sending input to bluetoothctl
    local fifo="$(mktemp -u)"
    mkfifo "$fifo"
    exec 3<>"$fifo"

    # issue commands, look for responses, quit on error or when done
    local command_number=0
    local max_command_number="$(expr ${#_commands[@]} - 1)"
    local response_seen=0
    local eof_seen=0
    local line=''
    local error=''
    local next_command_time=0
    # read from bluetoothctl one char at a time, without buffering
    while [[ "$eof_seen" != '1' ]]; do
        read -N 1 -t 0.25 -r char
        local retval=$?
        if [[ $retval != 0 ]]; then
            if [[ $retval -lt 128 ]]; then
                eof_seen=1
                continue
            fi
        fi

        printf "$char"
        [[ "$char" != $'\n' ]] && line="$line$char"

        if [[ "$char" == 'K' ]] && [[ "${#line}" -ge 4 ]] && [[ "${line: -4}" == '[K' ]]; then
            # bluetoothctl uses the above escape sequence to overwrite its own prompt
            # with each output line
            line=''
            continue
        elif [[ "$char" == 'm' ]]; then
            local size_to_test=0
            [[ "${#line}" -ge 9 ]] && size_to_test=9
            if [[ "${line: -$size_to_test}" =~ \[([0-9]{1,3}(;[0-9]{1,2})?)?m$ ]]; then
                # strip out color codes so our subsequent string comparisons will work
                line="${line: 0: -${#BASH_REMATCH[0]}}"
            fi
        fi
        
        if [[ "$char" != $'\n' ]]; then
            if [[ "$line" =~ ^\[.+\]#\ $ ]]; then
                if [[ -n "$error" ]]; then
                    echo "quit" >&3
                elif [[ "$response_seen" == '1' ]] && [[ "$(date +%s)" -ge "$next_command_time" ]]; then
                    # bluetoothctl is ready for the next command
                    if [[ "$command_number" -ge "$max_command_number" ]]; then
                        echo "quit" >&3
                    else
                        command_number="$(expr $command_number + 1)"
                        if [[ "${_commands[$command_number]}" =~ ^sleep\ [[:digit:]\.]+$ ]]; then
                            local duration="$( grep -oP '(?<=^sleep )[[:digit:].]+' <<< "${_commands[$command_number]}" )"
                            next_command_time="$(expr $(date +%s) + $duration)"
                        else
                            echo "${_commands[$command_number]}" >&3
                            [[ -z "${_responses[$command_number]}" ]] && response_seen=1 || response_seen=0
                        fi
                    fi
                fi
            elif [[ "$line" =~ ^\[agent\]\ Authorize\ service\ [0-9a-fA-F\-]+\ \(yes/no\):\ $ ]]; then
                echo "yes" >&3
            elif [[ "$line" =~ ^\[agent\]\ Confirm\ passkey\ [0-9]{6}\ \(yes/no\):\ $ ]]; then
                echo "yes" >&3
            elif [[ "$line" =~ ^\[agent\]\ PIN\ code:\ ([[:digit:]]{4,6})$ ]]; then
                local pin="${BASH_REMATCH[1]}"
                printMsgs "info" "Please enter PIN $pin (and press ENTER) on your Bluetooth device now."
            elif [[ "$line" =~ ^\[agent\]\ Enter\ PIN\ code:\ $ ]]; then
                local cmd=(dialog --nocancel --backtitle "$__backtitle" --menu "Which PIN do you want to use?" 22 76 16)
                local options=(
                    1 "0000"
                    2 "Enter your own"
                )
                local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
                local pin="0000"
                if [[ "$choice" == "2" ]]; then
                    pin=$(dialog --backtitle "$__backtitle" --inputbox "Please enter a pin" 10 60 2>&1 >/dev/tty)
                fi
                printMsgs "info" "Please enter PIN $pin (and press ENTER) on your Bluetooth device now."
                echo "$pin" >&3
            fi
        else
            if [[ "$response_seen" == "0" ]] && [[ "$line" == "${_responses[$command_number]}" ]]; then
                response_seen=1
            elif [[ "$line" =~ (^|[^[:alnum:]_])(ERROR|Error|error|FAILED|Failed|failed)([^[:alnum:]_]|$) ]]; then
                error="$line"
            fi
            line=''
        fi
    done < <(stdbuf -o0 bluetoothctl --agent="$capability" <&3 2>&1)

    # clean up
    exec 3>&-
    rm -f "$fifo"

    if [[ -n "$error" ]]; then
        printf "$error" >&2
        return 1
    fi
}

function _raw_list_known_devices_with_regex_bluetooth() {
    local regex="$1"
    local line
    while read line; do
        local mac="$(echo "$line" | grep --color=none -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')"
        if [[ -n "$mac" ]]; then
            # suppress stderr due to segfault bug in bluez 5.50
            local info; info="$(bt-device --info $mac 2>/dev/null)"
            if [[ "$?" == "0" ]] ; then
                if echo "$info" | grep -qzP --regex="$regex"; then
                    echo "$line"
                fi
            fi
        fi
    done < <(bt-device --list)
}

function _list_paired_connected_trusted_devices_bluetooth() {
    local line
    while read line; do
        if [[ "$line" =~ ^(.+)\ \((.+)\)$ ]]; then
            echo "${BASH_REMATCH[2]}"
            echo "${BASH_REMATCH[1]}"
        fi
    done < <(_raw_list_known_devices_with_regex_bluetooth '(?s)^(?=.*\b(Paired|Connected|Trusted): 1\b).*$')
}

function _list_connected_devices_bluetooth() {
    local line
    while read line; do
        if [[ "$line" =~ ^(.+)\ \((.+)\)$ ]]; then
            echo "${BASH_REMATCH[2]}"
            echo "${BASH_REMATCH[1]}"
        fi
    # PS3 (sixaxis) controllers never show as paired, so ignore Paired state
    done < <(_raw_list_known_devices_with_regex_bluetooth '(?s)^(?=.*\bConnected: 1\b).*$')
}

function _list_disconnected_devices_bluetooth() {
    local line
    while read line; do
        if [[ "$line" =~ ^(.+)\ \((.+)\)$ ]]; then
            echo "${BASH_REMATCH[2]}"
            echo "${BASH_REMATCH[1]}"
        fi
    # PS3 (sixaxis) controllers never show as paired, so include Trusted+Disconnected
    done < <(_raw_list_known_devices_with_regex_bluetooth '(?s)^(?=.*\b(Paired|Trusted): 1\b)(?=.*\bConnected: 0\b).*$')
}

function list_unpaired_devices_bluetooth() {
    local mac_address
    local device_name
    local info_text="Scanning for devices..."

    declare -A paired=()
    declare -A found=()

    # get an asc array of paired mac addresses
    while read mac_address; read device_name; do
        paired+=(["$mac_address"]="$device_name")
    done < <(_list_paired_connected_trusted_devices_bluetooth)

    # sixaxis: add USB pairing information
    [[ -n "$(lsmod | grep hid_sony)" ]] && info_text="$info_text\n\nPS3 sixaxis detection: while this text is visible, unplug the controller, press the pinhole reset button, then replug the controller."
    printMsgs "info" "$info_text"

    if hasPackage bluez 5; then
        local commands=(
            "default-agent"
            "scan on"
            "sleep 15"
            "scan off"
            "devices"
            )

        local responses=(
            "Default agent request successful"
            "Discovery started"
            ""
            "Discovery stopped"
            ""
            )

        while read mac_address; read device_name; do
            found+=(["$mac_address"]="$device_name")
        done < <(_bluetoothctl_cmds_bluetooth commands responses | grep "^Device " | cut -d" " -f2,3- | sed 's/ /\n/')
    else
        while read; read mac_address; read device_name; do
            found+=(["$mac_address"]="$device_name")
        done < <(hcitool scan --flush | tail -n +2 | sed 's/\t/\n/g')
    fi

    # display any found devices that are not already paired
    for mac_address in "${!found[@]}"; do
        if [[ -z "${paired[$mac_address]}" ]]; then
            echo "$mac_address"
            echo "${found[$mac_address]}"
        fi
    done
}

function display_all_paired_devices_bluetooth() {
    printMsgs "info" "Working..."

    local mac_address
    local device_name
    local connected=''
    while read mac_address; read device_name; do
        connected="$connected  $mac_address  $device_name\n"
    done < <(_list_connected_devices_bluetooth)
    [[ -z "$connected" ]] && connected="  <none>\n"

    local disconnected=''
    while read mac_address; read device_name; do
        disconnected="$disconnected  $mac_address  $device_name\n"
    done < <(_list_disconnected_devices_bluetooth)
    [[ -z "$disconnected" ]] && disconnected="  <none>\n"

    printMsgs "dialog" "Connected Devices:\n\n$connected\nDisconnected Devices:\n\n$disconnected"
}

function remove_paired_device_bluetooth() {
    declare -A mac_addresses=()
    local mac_address
    local device_name
    local options=()
    while read mac_address; read device_name; do
        mac_addresses+=(["$mac_address"]="$device_name")
        options+=("$mac_address" "$device_name")
    done < <(_list_paired_connected_trusted_devices_bluetooth)

    if [[ ${#mac_addresses[@]} -eq 0 ]] ; then
        printMsgs "dialog" "There are no devices to remove."
    else
        local cmd=(dialog --backtitle "$__backtitle" --menu "Which Bluetooth device do you want to remove?" 22 76 16)
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && return

        printMsgs "info" "Removing..."
        local out=$(bt-device --remove $choice 2>&1)
        if [[ "$?" -eq 0 ]] ; then
            printMsgs "dialog" "Device removed successfully."
        else
            printMsgs "dialog" "Error removing device:\n\n$out"
        fi
    fi
}

function _is_ps3_controller_bluetooth() {
    local device_name="$1"
    if [[ "$device_name" =~ PLAYSTATION\(R\)3\ Controller ]]; then
        return 0
    else
        return 1
    fi
}

function pair_device_bluetooth() {
    declare -A mac_addresses=()
    local mac_address
    local device_name
    local options=()

    while read mac_address; read device_name; do
        mac_addresses+=(["$mac_address"]="$device_name")
        options+=("$mac_address" "$device_name")
    done < <(list_unpaired_devices_bluetooth)

    if [[ ${#mac_addresses[@]} -eq 0 ]] ; then
        printMsgs "dialog" "No devices were found. Ensure your device is on, and try again."
        return
    fi

    local cmd=(dialog --backtitle "$__backtitle" --menu "Which Bluetooth device do you want to pair?" 22 76 16)
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ -z "$choice" ]] && return

    mac_address="$choice"
    device_name="${mac_addresses[$choice]}"

    printMsgs "info" "Pairing..."

    local commands=(
        "default-agent"
        "disconnect $mac_address"
        "unblock $mac_address"
        "trust $mac_address"
        )

    local responses=(
        "Default agent request successful"
        "Successful disconnected"
        "Changing $mac_address unblock succeeded"
        "Changing $mac_address trust succeeded"
        )

    if ! _is_ps3_controller_bluetooth "$device_name"; then
        commands+=(
            "pair $mac_address"
            "connect $mac_address"
            )
    
        responses+=(
            "Pairing successful"
            "Connection successful"
            )
    fi
    
    local errfile="$(mktemp)"
    if _bluetoothctl_cmds_bluetooth commands responses 1>/dev/null 2>"$errfile"; then
        if _is_ps3_controller_bluetooth "$device_name"; then
            printMsgs "dialog" "Successfully paired $device_name ($mac_address).\n\nUnplug it now and press the PS button to connect it wirelessly."
        else
            printMsgs "dialog" "Successfully paired and connected to $device_name ($mac_address)."
        fi
    else
        local error; error="$(<"$errfile")"
        rm "$errfile"
        local msg="An error occurred while trying to pair $device_name ($mac_address):\n\n$error"
        msg="$msg\n\nPlease try pairing with the command line tool 'bluetoothctl' instead."
        printMsgs "dialog" "$msg"
        return 1
    fi
}

function setup_joypad_udev_rule_bluetooth() {
    declare -A mac_addresses=()
    local mac_address
    local device_name
    local options=()
    while read mac_address; read device_name; do
        mac_addresses+=(["$mac_address"]="$device_name")
        options+=("$mac_address" "$device_name")
    done < <(_list_paired_connected_trusted_devices_bluetooth)

    if [[ ${#mac_addresses[@]} -eq 0 ]] ; then
        printMsgs "dialog" "There are no paired bluetooth devices."
    else
        local cmd=(dialog --backtitle "$__backtitle" --menu "Which Bluetooth device do you want to set up a udev rule for?" 22 76 16)
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && return
        device_name="${mac_addresses[$choice]}"
        local config="/etc/udev/rules.d/99-bluetooth.rules"
        if ! grep -q "$device_name" "$config"; then
            local line="SUBSYSTEM==\"input\", ATTRS{name}==\"$device_name\", MODE=\"0666\", ENV{ID_INPUT_JOYSTICK}=\"1\""
            addLineToFile "$line" "$config"
            printMsgs "dialog" "Added $line to $config\n\nPlease reboot for the configuration to take effect."
        else
            printMsgs "dialog" "An entry already exists for $device_name in $config"
        fi
    fi
}

function connect_all_disconnected_devices_bluetooth() {
    printMsgs "info" "Working..."
    local devices="$(_list_disconnected_devices_bluetooth)"
    if [[ -z "$devices" ]]; then
        printMsgs "dialog" "All devices are already connected."
        return 0
    fi

    local mac_address
    local device_name
    local connected=''
    local errored=''
    while read mac_address; read device_name; do
        printMsgs "info" "Connecting to $mac_address $device_name..."
        local output
        output="$(bt-device --connect "$mac_address" 2>&1)"
        if [[ "$?" != "0" ]]; then
            errored="$errored  $mac_address  $device_name\n"
            printMsgs "dialog" "Error while connecting to $mac_address $device_name:\n\n$output"
        else
            connected="$connected  $mac_address  $device_name\n"
        fi
    done < <(echo "$devices")

    local msg=''
    if [[ -n "$connected" ]]; then
        msg="Connected successfully:\n\n$connected"
    fi
    if [[ -n "$errored" ]]; then
        msg="Connection failed:\n\n$errored"
    fi
    printMsgs "dialog" "$msg"
}

function connect_mode_gui_bluetooth() {
    local mode="$(_get_connect_mode_bluetooth)"
    [[ -z "$mode" ]] && mode="default"

    local cmd=(dialog --backtitle "$__backtitle" --default-item "$mode" --menu "Which Bluetooth connection mode do you want to use?" 22 76 16)

    local options=(
        default "Bluetooth stack default behaviour (recommended)"
        boot "Connect to devices once at boot"
        background "Force connecting to devices in the background"
    )

    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ -n "$choice" ]] && connect_mode_set_bluetooth "$choice"
}

function connect_mode_set_bluetooth() {
    local mode="$1"
    [[ -z "$mode" ]] && mode="default"

    local config="/etc/systemd/system/connect-bluetooth.service"
    case "$mode" in
        boot|background)
            mkdir -p "$md_inst"
            sed -e "s#CONFIGDIR#$configdir#" -e "s#ROOTDIR#$rootdir#" "$md_data/connect.sh" >"$md_inst/connect.sh"
            chmod a+x "$md_inst/connect.sh"
            cat > "$config" << _EOF_
[Unit]
Description=Connect Bluetooth

[Service]
Type=simple
ExecStart=nice -n19 "$md_inst/connect.sh"

[Install]
WantedBy=multi-user.target
_EOF_
            systemctl enable "$config"
            ;;
        default)
            if systemctl is-enabled connect-bluetooth 2>/dev/null | grep -q "enabled"; then
               systemctl disable "$config"
            fi
            rm -f "$config"
            rm -rf "$md_inst"
            ;;
    esac
    iniConfig "=" '"' "$configdir/all/bluetooth.cfg"
    iniSet "connect_mode" "$mode"
    chown $user:$user "$configdir/all/bluetooth.cfg"
}

function gui_bluetooth() {
    addAutoConf "8bitdo_hack" 0

    while true; do
        local connect_mode="$(_get_connect_mode_bluetooth)"

        local cmd=(dialog --backtitle "$__backtitle" --menu "Configure Bluetooth Devices" 22 76 16)
        local options=(
            P "Pair a Bluetooth device"
            C "Connect all disconnected Bluetooth devices"
            D "Display all paired Bluetooth devices"
            X "Remove a paired Bluetooth device"
            U "Set up udev rule for Bluetooth joypad (required for 8Bitdo, etc)"
            M "Change Bluetooth connect mode (currently: $connect_mode)"
        )

        local atebitdo
        if getAutoConf 8bitdo_hack; then
            atebitdo=1
            options+=(8 "8Bitdo mapping hack (ON - old firmware)")
        else
            atebitdo=0
            options+=(8 "8Bitdo mapping hack (OFF - new firmware)")
        fi

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            # temporarily restore Bluetooth stack (if needed)
            service sixad status &>/dev/null && sixad -r
            case "$choice" in
                P)
                    pair_device_bluetooth
                    ;;
                X)
                    remove_paired_device_bluetooth
                    ;;
                D)
                    display_all_paired_devices_bluetooth
                    ;;
                U)
                    setup_joypad_udev_rule_bluetooth
                    ;;
                C)
                    connect_all_disconnected_devices_bluetooth
                    ;;
                M)
                    connect_mode_gui_bluetooth
                    ;;
                8)
                    atebitdo="$((atebitdo ^ 1))"
                    setAutoConf "8bitdo_hack" "$atebitdo"
                    ;;
            esac
        else
            # restart sixad (if running)
            service sixad status &>/dev/null && service sixad restart && printMsgs "dialog" "NOTICE: The ps3controller driver was temporarily interrupted in order to allow compatibility with standard Bluetooth peripherals. Please re-pair your Dual Shock controller to continue (or disregard this message if currently using another controller)."
            break
        fi
    done
}
