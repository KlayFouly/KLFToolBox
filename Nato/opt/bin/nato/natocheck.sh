#!/bin/bash


function scanner() {
    # Scan the network for active hosts
    for ip in $(nmap -sn 172.16.128.0/24 | grep "Nmap scan report for" | awk '{print $5}'); do
        echo "Checking host with IP: $ip"
        local hostname=$(nmap -O -sS $ip | grep "MAC Address:" | awk '{print $3}')

        if grep -q "$ip" /var/lib/nato/hosts; then
            echo "Host $ip already exists in hosts"
        else
            sudo /opt/bin/nato/nato-create-host.sh -H $hostname -a $ip -g default
        fi

        # Check if the IP is already in activehosts.dat
        if grep -q "$ip" /var/lib/nato/activehosts; then
            echo "Host $ip already exists in activehosts"
        else
            echo "$ip" >> /var/lib/nato/activehosts
        fi
    done
}


    # Check if the hosts.cfg file exists
if [[ ! -f /var/lib/nato/activehosts ]]; then
    echo "activehosts.dat not found, creating a new one."
    touch /var/lib/nato/activehosts
else
    rm /var/lib/nato/activehosts
    touch /var/lib/nato/activehosts
fi

scanner
# sudo /opt/bin/nato/nato-create-rules.sh

while true; do

    # Check for VMs in the network
    scanner

    for ip in $(cat /var/lib/nato/activehosts); do
        if ! nmap -sn $ip &> /dev/null; then
            echo "Host $ip is no longer reachable, removing from activehosts"
            sed -i "/$ip/d" /var/lib/nato/activehosts
            /opt/bin/nato/nato-del-rule.sh -r $ip
        fi
    done
done