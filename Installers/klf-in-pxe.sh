#!/bin/bash


function helper() {
    echo " Usage : $0 [ -m | --minimal ] [ -h | --help ]"
    echo " Options :"
    echo "    -m, --minimal : Minimal installation, it will only install a basic pxe menu without dhcp options (you will have to configure your own dhcp server to point to this pxe server)"
    echo "    -h, --help : Display this help message"
    echo "    -r, --root : Set the tftp root directory (Default is /srv/tftp)"
    exit 0
}

function varIni() {
    NET_INTERFACES=$(ls /sys/class/net)
    PXE_INTERFACE=""
    TFTP_ROOTDIR=/srv/tftp/
    DHCP=false
    count=0    
    OPTS=$(getopt -o hmr: --long help,minimal,root: -n 'klf-inf-pxe' -- "$@")
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

function userAccept() {
    
    while true; do
        echo $'A dhcp server will be installed on this machine, if you already have a dhcp server on your network it can lead to unwanted behavio\n'
        echo $'Are you sure you want to install a dhcp server on this system ? (if not you can use the -m parameter for minimal installation)\n\n'
        read -p "(y/n)" answer
        if [ $answer == "y" ];then
            DHCP=true
            break
        elif [ $answer == "n" ]; then
            exit 1
        else
            continue
        fi
    done
}

function fileManagement() {
    if[[ ! -d $TFTP_ROOTDIR ]];then
        sudo mkdir
    else
        ## already exist, do i erase it or keep it ?
}

function sortArgs() {
    eval set -- "$OPTS"
    
    while true;do
        case "$1" in
            -h | --help)
                helper
                shift
                break
                ;;
            -m | --minimal)
                DHCP=false
                shift
                ;;
            -r | --root)
                echo "$2"
                if [[ $2 == "" ]];then
                    echo "Argument missing for option $1"
                    exit 1
                fi
                TFTP_ROOTDIR=$2
                shift 2
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "$1 : Unknown options"
                exit 101
                ;;
        esac
    done
}

function main() {
    echo "PXE Server Installation"
    echo "Available network interfaces :"

    ## Display available network interfaces and ask User to select one ##
    
    disInt
    selInt
}

function packInst() {
    ## Packages : dnsmasq syslinux pxelinux nfs-kernel-server
    sudo apt-get install dnsmasq nfs-kernel-server
    sudo apt-get install syslinux pxelinux
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

## Initialize the variables ##

varIni "$@"
sortArgs

## Runing main program function

main "$@"

echo "PXE interface : $PXE_INTERFACE"
echo "PXE interface selected successfully"