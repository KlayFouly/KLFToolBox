#!/bin/bash

OPTS=$(getopt -o ha:H:g:p:d: --long help,address:,hostname:,goup:,port:,delete: -n 'nato' -- "$@")
hostname=""
address=""
groups=()
ports=()


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
            -p | --port)
                echo $1
                ports+=$2
		        shift 2
                ;;
            -a | --address)
                echo $1
                address=$2
		        shift 2
                ;;
            -g | --group)
                echo $1
                groups+=$2
                shift 2
                ;;
            -H | --host)
                echo $1
                address=$2
                shift 2
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

function addHost() {
    
    local hostname=$1
    local ip=$2
    local groups=$3
    local ports=$4

    # Add the host to hosts.cfg
    if [[ $hostname == "" ]]; then
        echo "Hostname not found for IP $ip, using MAC as hostname"
        hostname=$(nmap -O -sS $ip| grep "MAC Address:" | awk '{print $3}')
    fi


    while IFS= read -r line; do
        if [[ $line == "    name $hostname" ]]; then
            #start reading
            echo "Host is already defined in /var/lib/nato/hosts"
            return 1
        fi
    done < /opt/hosts.cfg

    if [[ $groups == "" ]]; then
        groups="default"
    fi

    echo $'\n\n' >> /var/lib/nato/hosts
    echo "define host {" >> /var/lib/nato/hosts
    echo "    hostname $hostname" >> /var/lib/nato/hosts
    echo "    address $ip" >> /var/lib/nato/hosts
    local groupline="    "
    for group in $groups; do
        groupline+="$group "
    done
    echo "$groupline" >> /var/lib/nato/hosts
    local portline="    "
    for port in $ports; do
        portline+="$port "
    done
    echo $portline >> /var/lib/nato/hosts
    echo "}" >> /var/lib/nato/hosts
    echo "Host $ip added to hosts.cfg with hostname $hostname"
}

add_Host $hostname $address $groups $ports






function attributePort() {
    # Get the last attributed port
    local last_port=$(cat /var/lib/nato/lastattributedport)

    # Increment the port number
    local new_port=$((last_port + 1))

    # Check if the new port is reserved
    if grep -q "$new_port" /var/lib/nato/reservedports.cfg; then
        echo "Port $new_port is reserved, skipping"
        return 1
    fi

    # Update the last attributed port file
    echo "$new_port" > /var/lib/nato/lastattributedport
    echo "$new_port" >> /var/lib/nato/reservedports.cfg

    echo "$new_port"
}

## add host (to file)
# param : -H hostname  -a ip  -g group -p ports+

# tab[group1 group2 ...]
# tab[port1, port2, port+1, port+2 ...]