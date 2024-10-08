#!/usr/bin/env bash

# (C) Sergey Tyurin  2024-09-02 13:00:00

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
echo "################################## Update env.sh Script ########################################"
echo "INFO: $(basename "$0") BEGIN $(date +%s) / $(date  +'%F %T %Z')"

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"

#################################################################
# Set new environment variables in env.sh
sed -i.bak "s|export RUST_VERSION=.*|export RUST_VERSION=\"1.81.0\"|; \
            s|export Main_DApp_URL=.*|export Main_DApp_URL=\"https://mainnet.evercloud.dev\"|; \
            s|export MainNet_DApp_List=.*|export MainNet_DApp_List=\"https://mainnet.evercloud.dev,https://gra01.main.everos.dev,https://lim01.main.everos.dev\"|; \
            s|export DevNet_DApp_URL=.*|export DevNet_DApp_URL=\"https://devnet.evercloud.dev\"|; \
            s|export DevNet_DApp_List=.*|export DevNet_DApp_List=\"https://devnet.evercloud.dev,https://eri01.net.everos.dev,https://gra01.net.everos.dev\"|; \
            s|export MIN_TC_VERSION=.*|export MIN_TC_VERSION=\"0.40.0\"|; \
            s|export RNODE_GIT_REPO=.*|export RNODE_GIT_REPO=\"https://github.com/everx-labs/ever-node.git\"|g; \
            s|export TONOS_CLI_GIT_REPO=.*|export TONOS_CLI_GIT_REPO=\"https://github.com/everx-labs/ever-cli.git\"|; \
            s|export CONTRACTS_GIT_REPO=.*|export CONTRACTS_GIT_REPO=\"https://github.com/everx-labs/ton-labs-contracts.git\"|; \
            s|export Node_Blk_Min_Ver=.*|export Node_Blk_Min_Ver=58|" "${SCRIPT_DIR}/env.sh"

sed -i.bak "s|export TONOS_CLI_SRC_DIR=.*|export TONOS_CLI_SRC_DIR=\"${NODE_TOP_DIR}/ever-cli\"|; \
            s|export CALL_TC=.*|export CALL_TC=\"${NODE_BIN_DIR}/ever-cli -c $SCRIPT_DIR/ever-cli.conf.json\"|" \
            ${SCRIPT_DIR}/env.sh

#################################################################
# Add DAPP_Project_id & DAPP_access_key variables 
# if [[ -z "$(cat ${SCRIPT_DIR}/env.sh | grep 'export DAPP_access_key')" ]];then
#     sed -i.bak '/# Networks endpoints/p; s/# Networks endpoints.*/export DAPP_access_key=""/' ${SCRIPT_DIR}/env.sh
# fi

# if [[ -z "$(cat ${SCRIPT_DIR}/env.sh | grep 'export DAPP_Project_id')" ]];then
#     sed -i.bak '/# Networks endpoints/p; s/# Networks endpoints.*/export DAPP_Project_id=""/' ${SCRIPT_DIR}/env.sh
# fi

# if [[ -z "$(cat ${SCRIPT_DIR}/env.sh | grep 'export Auth_key_Head')" ]];then
#     sed -i.bak '/# Networks endpoints/p; s/# Networks endpoints.*/export Auth_key_Head="Authorization: Basic "/' ${SCRIPT_DIR}/env.sh
# fi

# if [[ -z "$(cat ${SCRIPT_DIR}/env.sh | grep 'export Tg_Exclaim_sign')" ]];then
#     sed -i.bak '/export Tg_Warn_sign/p; s/export Tg_Warn_sign.*/export Tg_Exclaim_sign=$(echo -e "\\U000203C")/' ${SCRIPT_DIR}/env.sh
# fi

source "${SCRIPT_DIR}/env.sh"
if [[ ! -x ${NODE_BIN_DIR}/ever-cli ]];then
    ./upd_ever-cli.sh
fi

if [[ -z "$DAPP_Project_id" ]];then
    "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "$Tg_Exclaim_sign $(cat "${SCRIPT_DIR}/Update_Info.txt") $Tg_Exclaim_sign" > /dev/null 2>&1
fi

echo "+++INFO: $(basename "$0") FINISHED $(date +%s) / $(date  +'%F %T %Z')"
echo "================================================================================================"

exit 0
