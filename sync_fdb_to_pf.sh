#!/bin/bash

USAGE="Usage: $0 [write|restore] bridge_name parent_interface"

if [ "$#" -ne "3" ]; then
  echo "$USAGE"
  exit 1
fi

# First argument is the vmid



action=$1
case "${action}" in
  write|restore) : ;;
  *)                                       echo "got unknown action ${action}"; exit 1 ;;
esac

bridge_name=$2
parent_interface=$3

# Function to check if a MAC address is a multicast MAC address
is_unicast_mac() {
    # Check if the input is a valid MAC address with 6 colon-separated hexadecimal pairs
    local mac="$1"
    local regex='^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$'
    if [[ ! "$mac" =~ $regex ]]; then
        echo "Invalid MAC address format"
        return 1
    fi
    
    # Extract the first byte of the MAC address
    local first_byte="${mac%%:*}"
    
    # Convert the first byte to decimal
    local first_byte_decimal=$((16#${first_byte}))
    
    # Check if the least significant bit of the first byte is 1 (multicast)
    if ((first_byte_decimal % 2 == 1)); then
        return 1
    else
        return 0
    fi
}


function get_unicast_mac {
    while read -r line ; do
        is_unicast_mac "$line" && echo "$line"
    done
}

read -r -d '' -a src_macpool < <(bridge fdb show brport $parent_interface | grep -v master | awk '{print $1}' | get_unicast_mac)
read -r -d '' -a dst_macpool < <(bridge fdb show br $bridge_name state 2 | grep -E " tap| veth| fwpr" | awk '{print $1}' | sort | uniq -u | get_unicast_mac)

set -e

function sync_to_fdb {
    for src_macpool_addr in "${src_macpool[@]}"; do
        found=false
        for dst_macpool_addr in "${dst_macpool[@]}"; do
            if [ "$src_macpool_addr" = "$dst_macpool_addr" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            echo "bridge fdb del $src_macpool_addr dev $parent_interface"
            bridge fdb del $src_macpool_addr dev $parent_interface
        fi
    done
    
    for dst_macpool_addr in "${dst_macpool[@]}"; do
        found=false
        for src_macpool_addr in "${src_macpool[@]}"; do
            if [ "$dst_macpool_addr" = "$src_macpool_addr" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            echo "bridge fdb add $dst_macpool_addr dev $parent_interface"
            bridge fdb add $dst_macpool_addr dev $parent_interface
        fi
    done
}

function restore_fdb {
    for src_macpool_addr in "${src_macpool[@]}"; do
        echo "bridge fdb del $src_macpool_addr dev $parent_interface"
        bridge fdb del $src_macpool_addr dev $parent_interface
    done
}

case "${action}" in
  write) 
    sync_to_fdb
    ;;
  restore)
    restore_fdb
    ;;
esac

exit 0
