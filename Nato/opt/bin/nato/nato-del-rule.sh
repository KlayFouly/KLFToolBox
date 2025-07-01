#!/bin/bash

OPTS=$(getopt -o hf:a:p:P:tu --long help,fullremove:address:,dport:,dest:,tcp:,udp: -n 'nato' -- "$@")
removedHost=""
address=""
dport=""
dest=""
tcp="false"
udp="false"
protocol=""


function helper() {
    echo " Usage : $0 [ -d | --database DATABASE ] [ -u | username ADMINNAME ] [ -l | --lamp ] [ -h | --help ]"
    echo " Options :"
    echo "    -a, --adress IP or Name : add a host to hosts.cfg"
    echo "    -p, --port PORT : create a nat redirection from port to port"
    echo "    -g, --group GROUP : add a group to the host"
    echo "    -H, --hostname HOSTNAME : set the hostname for the host"
    echo "    -h, --help : Display this help message"
    exit 0
}

function sortArgs() {

    eval set -- "$OPTS"

    while true; do
        case "$1" in
            -f | --fullremove)
                echo $1
                removedHost=$2
                shift 2
                ;;
            -a | --address)
                echo $1
                address=$2
		        shift 2
                ;;
            -p | --dport)
                echo $1
                dport=$2
		        shift 2
                ;;
            -P | --dest)
                echo $1
                dest=$2
                shift 2
                ;;
            -t | --tcp)
                echo $1
                tcp="true"
                shift
                ;;
            -u | --udp)
                echo $1
                udp="true"
		        shift
                ;;
            -h | --help)
                echo $0
                helper
		        shift
                ;;
            --)
                echo $1
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



sortArgs

if [[ $fullremove == "" ]]; then
    # use args to remove a rule

    if [[ $tcp == "true" && $udp == "true" ]]; then
        protocol="both"
    elif [[ $tcp == "true" && $udp == "false" ]]; then
        protocol="tcp"
    elif [[ $tcp == "false" && $udp == "true" ]]; then
        protocol="udp"
    elif [[ $tcp == "false" && $udp == "false" ]]; then
        protocol="tcp"
    fi


else
    sed -i "/$removedHost/d" "/var/lib/nato/currentrules"
fi
