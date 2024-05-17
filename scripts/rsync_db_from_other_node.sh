#!/usr/bin/env bash

# (C) Sergey Tyurin  2024-01-26 10:00:00

# Disclaimer
##################################################################################################################
# You running this script/function means you will not blame the author(s)
# if this breaks your stuff. This script/function is provided AS IS without warranty of any kind. 
# Author(s) disclaim all implied warranties including, without limitation, 
# any implied warranties of merchantability or of fitness for a particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts and documentation remains with you.
# In no event shall author(s) be held liable for any damages whatsoever 
# (including, without limitation, damages for loss of business profits, business interruption, 
# loss of business information, or other pecuniary loss) arising out of the use of or inability 
# to use the script or documentation. Neither this script/function, 
# nor any part of it other than those parts that are explicitly copied from others, 
# may be republished without author(s) express written permission. 
# Author(s) retain the right to alter this disclaimer at any time.
##################################################################################################################

echo
echo "################################# Copy DB from other node ######################################"
echo "INFO: $(basename "$0") BEGIN $(date +%s) / $(date  +'%F %T %Z')"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "${SCRIPT_DIR}/env.sh"

# Determine OS
OS_TYPE=$(uname -s)

# Check node is not running
if [[ "$OS_TYPE" == "Linux" ]]; then
    NODE_ACTIVE=$(systemctl is-active tonnode)
elif [[ "$OS_TYPE" == "FreeBSD" ]]; then
    NODE_ACTIVE=$(service tonnode status 2>/dev/null | grep -c 'is running')
else
    echo "Unsupported OS"
    exit 1
fi

if [[ "$NODE_ACTIVE" == "active" || "$NODE_ACTIVE" -gt 0 ]]; then
    echo "Node is running. Stop node before rsync and delete old db"
    exit 1
fi

REMOTE_NODE=${1}
# check if the node name is present in ~/.ssh/config
if ! grep -q "Host ${REMOTE_NODE}" ~/.ssh/config; then
    echo "The node name must be present in ~/.ssh/config"
    exit 1
fi

# Use rsync with sudo on the remote side
RSYNC_CMD="sudo rsync"

# Set the owner of the local node db to the current user
sudo chown $(id -un):$(id -gn) "$R_DB_DIR" -R

# Copy db from remote node to local node
for ((i=1; i <= 5; i++)); do
    echo "---INFO Downloading db from $REMOTE_NODE attempt $i"
    rsync -arz --ignore-errors --delete \
        $REMOTE_NODE:$R_DB_DIR/ \
        "$R_DB_DIR" \
        --exclude 'catchains/'
done

# Start node
if [[ "$OS_TYPE" == "Linux" ]]; then
    sudo systemctl start tonnode
elif [[ "$OS_TYPE" == "FreeBSD" ]]; then
    sudo service tonnode start
fi

echo
echo "+++INFO: $(basename "$0") FINISHED $(date +%s) / $(date)"
echo "================================================================================================"

exit 0
