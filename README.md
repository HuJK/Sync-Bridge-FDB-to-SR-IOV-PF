## Script
This script make VMs under pf bridges be able to communicate with VMs that under VFs in SR-IOV

It will read mac address learned from bridge and sync to the FDB table.
Run this script periodically.
Inspired by https://github.com/jdlayman/pve-hookscript-sriov

## Usage

```
Usage: ./sync_mac_to_br.sh [write|clear] $bridge_name $parent_interface
```

### Sync every 10 seconds

In this example  
vmbr1001 is the bridge name  
ens1f1 is the parent interface  

Add this to your crontab
```
* * * * *             /root/sync_mac_to_br.sh write vmbr1001 ens1f1
* * * * * sleep 10 && /root/sync_mac_to_br.sh write vmbr1001 ens1f1
* * * * * sleep 20 && /root/sync_mac_to_br.sh write vmbr1001 ens1f1
* * * * * sleep 30 && /root/sync_mac_to_br.sh write vmbr1001 ens1f1
* * * * * sleep 40 && /root/sync_mac_to_br.sh write vmbr1001 ens1f1
* * * * * sleep 50 && /root/sync_mac_to_br.sh write vmbr1001 ens1f1
```


