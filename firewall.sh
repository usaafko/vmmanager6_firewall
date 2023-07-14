#!/bin/sh

###
### Firewall script for VMmanager 6
### AO Exo-soft 2023
### Author: Kalinichenko Ilya
### mailto: i.kalinichenko@ispsystem.com
###

usage() {
        cat << EOF
Usage:
	firewall.sh [vm_name] [list] - list rules for vm
	firewall.sh [vm_name] [remove <handle>] - remove rule for vm
	firewall.sh [vm_name] [add --direction <in|out> [--ip <ip>] [--ports <ports>]] - add rule for vm
EOF
}
NC='\033[0m' # No Color

pprint() {
        GREEN='\033[0;32m'
        echo -e "===> $(date) ${GREEN}${1}${NC}"
}
perror() {
        RED='\033[0;31m'
        echo -e "===> $(date) ${RED}${1}${NC}"
}
list_rules() {
	if [ $(check_chain) -ne 0 ]; then
		perror "There is no rules for $vm_name"
		exit
	fi
	nft --handle list chain inet filter vm${vm_id}-ports
}
remove_rule() {
	if [ -z "$1" ]; then
		usage
		exit
	fi
	if [ $(check_chain) -ne 0 ]; then
		perror "There is no rules for $vm_name"
		exit
	fi
	pprint "Deleting rule handle $1 for $vm_name"
	nft delete rule inet filter vm${vm_id}-ports handle $1
	if [ $? -eq 0 ];then
		pprint "Saving config file..."
		save_file
	else
		perror "Can't delete rule"
	fi
	pprint "Done"
}
check_chain() {
	nft list chain inet filter vm${vm_id}-ports 2>/dev/null >/dev/null
	if [ $? -ne 0 ]; then
		echo 1
	else
		echo 0
	fi
}
save_file() {
	tmpfile=$(mktemp /tmp/firewall_XXXXX)
	tmpfile2=$(mktemp /tmp/firewall2_XXXXX)
	pattern='/chain vm'$vm_id'-ports \{/,/^\W+}'
	nft  -s list chain inet filter vm${vm_id}-ports | sed -n -E "$pattern/p" > $tmpfile
	sed -E "$pattern/c_PATTERN_" /etc/nftables/vm/$vm_name.nft | sed -e "/_PATTERN_/r $tmpfile" -e "/_PATTERN_/d" > $tmpfile2
	mv $tmpfile2 /etc/nftables/vm/$vm_name.nft
	rm -f $tmpfile $tmpfile2
}
add_rule() {
	case "$direction" in
		in)
			dir_int="oifname"
			dir_ip="ip saddr"
			;;
		out)
			dir_int="iifname"
			dir_ip="ip daddr"
			;;
		*)	
			usage
			exit
			;;
	esac
	rule=""
	if [ -n "$ip" ]; then
		rule="$dir_ip $ip"
	fi
	if [ -n "$ports" ];  then
		rule="$rule th dport { $ports }"
	fi
	if [ -z "$rule" ]; then
		usage
		exit
	fi
	interfaces=$(virsh domiflist $vm_name | awk 'NR>2 {printf "%s ",$1}')
	for interface in $interfaces
	do
		pprint "Adding rule for $interface of $vm_name"
		nft add rule inet filter vm${vm_id}-ports $dir_int "$interface" meta l4proto '{tcp,udp}' $rule counter drop
		if [ $? -ne 0 ]; then
			perror "Can't add this rule. Stopping"
			exit
		fi
	done
	
	pprint "Saving configuration..."
	save_file
	pprint "Done"
	
}

if [ -z "$1" ]; then
        usage
        exit
fi

vm_name=$1
shift
vm_id=${vm_name%%_*}
case "$1" in
	list) list_rules;;
	remove) remove_rule $2;;
	add) shift
		while [ $# -gt 0 ]
	do
		case "$1" in
			--direction) 
				direction="$2"
				shift 2
				;;
			--ip)
				ip="$2"
				shift 2
				;;
			--ports)
				ports="$2"
				shift 2
				;;
			*)
				usage
				exit
				;;
		esac
	done
	add_rule
	;;
	*) usage;;
esac

