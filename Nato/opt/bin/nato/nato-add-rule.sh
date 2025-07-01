#!/bin/bash

OPTS=$(getopt -o ha:p:P:tu --long help,address:,dport:,dest:,tcp:,udp: -n 'nato' -- "$@")
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

currentruleformat="22222:172.16.128.1.100:20:tcp"


if [[ $tcp == "true" && $udp == "true" ]]; then
    protocol="both"
elif [[ $tcp == "true" && $udp == "false" ]]; then
    protocol="tcp"
elif [[ $tcp == "false" && $udp == "true" ]]; then
    protocol="udp"
elif [[ $tcp == "false" && $udp == "false" ]]; then
    protocol="tcp"
fi

if [[ $protocol == "both" ]]; then

    for rule in $(cat /var/lib/nato/currentrules); do
        if [[ $rule == "$dport:$address:$dest:tcp" ]]; then
            sed -i "s/$dport:$address:$dest:tcp/d" "/var/lib/nato/currentrules"
        fi
        if [[ $rule == "$dport:$address:$dest:udp" ]]; then
            sed -i "s/$dport:$address:$dest:udp/d" "/var/lib/nato/currentrules"
        fi
    done

    echo "$dport:$address:$dest:tcp" >> /var/lib/nato/currentrules
    sudo iptables -t nat -A PREROUTING -i $interface -p tcp --dport $dport -j DNAT --to-destination $address:$dest

    echo "$dport:$address:$dest:udp" >> /var/lib/nato/currentrules
    sudo iptables -t nat -A PREROUTING -i $interface -p udp --dport $dport -j DNAT --to-destination $address:$dest
else
    for rule in $(cat /var/lib/nato/currentrules); do
        if [[ $rule == "$dport:$address:$dest:$protocol" ]]; then
            sed -i "s/$dport:$address:$dest:$protocol/d" "/var/lib/nato/currentrules"
        fi

        echo "$dport:$address:$dest:$protocol" >> /var/lib/nato/currentrules
        sudo iptables -t nat -A PREROUTING -i $interface -p $protocol --dport $dport -j DNAT --to-destination $address:$dest
    done
fi

# Create the new rule



# check if rule is in currentrule

# if yes exit
# if not add the rule to currentrule
