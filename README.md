
## Usage

```
Usage: ./sync_mac_to_br.sh [write|restore] bridge_name parent_interface
```

Add this to your crontab
```
 * * * * * /root/sync_mac_to_br.sh write vmbr1001 ens1f1
```

vmbr1001 is bridge name
ens1f1 is the parent interface