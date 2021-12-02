# main.evs.dev
Script set for EVERSCALE main network

Setup you OS: increase **nofiles** and etc. 

```bash
git clone https://github.com/Custler/main.evs.dev.git
cd main.evs.dev/scripts/
./Nodes_Build.sh rust
./Setup.sh
sudo service tonnode start
# sync will start within 1h
./check_node_sync_status.sh 
```
