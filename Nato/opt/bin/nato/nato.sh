#!/bin/bash
set -e


sudo /opt/bin/nato/nato-check.sh














network="172.16.128.0/24"
OPTS=$(getopt -o ha:d: --long help,add:,delete: -n 'nato' -- "$@")
hostname=""

function helper() {
    echo " Usage : $0 [ -d | --database DATABASE ] [ -u | username ADMINNAME ] [ -l | --lamp ] [ -h | --help ]"
    echo " Options :"
    echo "    -d, --delete IP or Name : delete a host from hosts.cfg"
    echo "    -a, --add IP or Name : add a host to hosts.cfg"
    echo "    -p, --port PORT:PORT : create a nat redirection from port to port"
    echo "    -g, --group GROUP : add a group to the host"
    echo "    -H, --hostname HOSTNAME : set the hostname for the host"
    echo "    -h, --help : Display this help message"
    exit 0
}

# NATO - Nat Automation Tool

# Check for vm ?
# get vm ip
# set check hosts.cfg for nat rule
    #if rule exist => iptables
    #if no rule => add host to hosts.cfg
# Check Group 
    # if group check port to map => override if necessary
        # iptables

function sortArgs() {

    eval set -- "$OPTS"

    while true; do
        case "$1" in
            -d | --delete)
                echo $1
                WP_DB_NAME=$2
		        shift 2
                ;;
            -a | --add)
                echo $1
                ip=$2
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


# check ip in hosts.cfg
# 












for ip in $(nmap -sn 172.16.128.0/24 | grep "Nmap scan report for" | awk '{print $5}'); do
    echo "Found VM with IP: $ip"
    check_Hosts $ip
    for ip in $(cat /opt/hosts.cfg | grep -v '^#' | grep "ip=" | awk '{print $1}'); do
        if [[ "$ip" == "$ip" ]]; then
            echo "Host $ip already exists in hosts.cfg"
        else
            echo "Adding host $ip to hosts.cfg"
        fi
    done
done

function check_Hosts() {
    ip=$1

    for ip in $(cat /opt/hosts.cfg | grep -v '^#' | grep "ip=" | awk '{print $1}'); do
        if [[ "$ip" == "$1" ]]; then
            echo "Host $1 already exists in hosts.cfg"
            return 0
        fi
    done

    echo "Host $1 does not exist in hosts.cfg"
    addHost $ip

    return 1
}

function start_host_redirection() {
    local ip=$1
    local dport=$2
    local destination="$ip:$3"
    local protocol=$4

    # Check if the port is already in use
    if grep -q "$port" /opt/currentports.cfg; then
        echo "Port $port is already in use, skipping redirection for $ip"
        return 0
    fi

    # Add the port to currentports.cfg
    echo "$port" >> /opt/currentports.cfg

    # Add iptables rule for NAT redirection
    iptables -t nat -A PREROUTING -p $protocol --dport $dport -j DNAT --to-destination $destination

    echo "NAT redirection added for $destination on port $dport"
}

function add_Host() {
    
    local hostname=$1
    local ip=$2
    local port=$3
    local group=$4


    # Add the host to hosts.cfg
    if [[ $hostname == "" ]]; then
        echo "Hostname not found for IP $ip, using MAC as hostname"
        hostname=$(nmap -O -sS $ip| grep "MAC Address:" | awk '{print $3}')
    fi

    echo $'\n\n' >> /opt/hosts.cfg
    echo "define host {" >> /opt/hosts.cfg
    echo "    hostname $hostname" >> /opt/hosts.cfg
    echo "    ip $ip" >> /opt/hosts.cfg
    echo "    group default" >> /opt/hosts.cfg
    echo "    port 22:22222" >> /opt/hosts.cfg
    echo "}" >> /opt/hosts.cfg
    echo "Host $ip added to hosts.cfg with hostname $hostname"
}

function delete_Host() {
    local hostname

    # Check if the host exists in hosts.cfg
    if grep -q "hostname $hostname" /opt/hosts.cfg; then
        sed -i "/hostname $hostname/d" /opt/hosts.cfg
        echo "Host $hostname deleted from hosts.cfg"
    else
        echo "Host $hostname not found in hosts.cfg"
    fi
}

function attributePort() {
    # Get the last attributed port
    local last_port=$(cat /opt/lastattributedport)

    # Increment the port number
    local new_port=$((last_port + 1))

    # Check if the new port is reserved
    if grep -q "$new_port" /opt/reservedports.cfg; then
        echo "Port $new_port is reserved, skipping"
        return 1
    fi

    # Update the last attributed port file
    echo "$new_port" > /opt/lastattributedport
    echo "$new_port" >> /opt/reservedports.cfg

    echo "New port attributed: $new_port"
    return 0
}