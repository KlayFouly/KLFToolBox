#!/bin/bash

function main() {
    echo "PXE Server Installation"

    ## Initialize the variables ##
    varIni
    
    echo "Available network interfaces :"

    ## Display available network interfaces and ask User to select one ##
    
    disInt
    selInt
}

function varIni() {
    NET_INTERFACES=$(ls /sys/class/net)
    PXE_INTERFACE=""
    count=0
    RED='\033[0;31m'
    NC='\033[0m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    BOLD='\033[1m'
    UNDERLINE='\033[4m'
}

function disInt() {
    for i in $NET_INTERFACES; do
        if [ $i == "lo" ]; then
            continue
        fi
        count=$((count+1))
        echo "$count : $i"
    done
}

function selInt() {
    while true; do
        read -p "Select the interface used by your PXE server : " interface
        if [[ ! $interface =~ ^[0-9] ]]; then
            echo "Need an interface number"
            continue
        else
            if [[ $interface -gt $count ]]; then
                echo "Need and interface number"
                continue
            fi
            intCount=0
            for i in $NET_INTERFACES; do
                if [[ $i == "lo" ]]; then
                    continue
                fi
                intCount=$((intCount+1))
                if [ $interface -eq $intCount ]; then
                    PXE_INTERFACE=$i
                    break
                fi
            done
            echo -e "${GREEN}You have selected ${RED}${BOLD}${PXE_INTERFACE}${NC} as PXE interface"
            read -p "Do you want to continue? (y/n) : " choice > /dev/null
            if [ $choice == "y" ]; then
                break
            else
                continue
            fi
        fi
    done
}

main

echo "PXE interface : $PXE_INTERFACE"
echo "PXE interface selected successfully"