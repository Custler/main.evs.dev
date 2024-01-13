#!/usr/bin/env bash

# (C) Sergey Tyurin  2023-12-27 10:00:00

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
echo "##################################### Postupdate Script ########################################"
echo "INFO: $(basename "$0") BEGIN $(date +%s) / $(date  +'%F %T %Z')"

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/functions.shinc"

Timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
#===========================================================
#  Update network global config
${SCRIPT_DIR}/nets_config_update.sh

#===========================================================
# Check node version for DB reset
Node_bin_ver="$(rnode -V | grep 'Node, version' | awk '{print $4}')"
Node_bin_ver_NUM=$(echo $Node_bin_ver | awk -F'.' '{printf("%d%03d%03d\n", $1,$2,$3)}')
Node_SVC_ver="$($CALL_RC -jc getstats 2>/dev/null|cat|jq -r '.node_version' 2>/dev/null|cat)"
Node_SVC_ver_NUM=$(echo $Node_SVC_ver | awk -F'.' '{printf("%d%03d%03d\n", $1,$2,$3)}')

Node_bin_ver_NUM=$((10#${Node_bin_ver_NUM}))
Node_SVC_ver_NUM=$((10#${Node_SVC_ver_NUM}))
#########################
Chng_Config_ver=000055063
#########################
Chng_Config_ver=$((10#${Chng_Config_ver}))

#===========================================================
# Check Node Updated, GC set and restarted
if [[ $Node_bin_ver_NUM -ge $Chng_Config_ver ]] && \
   [[ $Node_bin_ver_NUM -eq $Node_SVC_ver_NUM ]] && \
   [[ "$(cat ${R_CFG_DIR}/config.json | jq '.gc.enable_for_archives' 2>/dev/null|cat)" == "true" ]];then
   echo "INFO: Check Node Updated - PASSED"
   exit 0
fi

#===========================================================
# For node ver >= 0.55.63 we have to change config.json
if [[ $Node_bin_ver_NUM -ge $Chng_Config_ver ]] && \
   [[ $Node_bin_ver_NUM -ne $Node_SVC_ver_NUM ]];then
    # Fix orphographic error in config.json
    sed -i.bak 's/prefill_cells_cunters/prefill_cells_counters/' ${R_CFG_DIR}/config.json

    # Backup node config file
    cp ${R_CFG_DIR}/config.json ${NODE_LOGS_ARCH}/config.json.${Timestamp}
    # Set new parametrs in config.json
    Remp_Config='{
        "client_enabled": true,
        "remp_client_pool": null,
        "service_enabled": true,
        "max_incoming_broadcast_delay_millis": 0,
        "remp.message_queue_max_len": 10000
    }'
    Cells_DB_Config='{
        "states_db_queue_len": 1000,
        "max_pss_slowdown_mcs": 750,
        "prefill_cells_counters": false,
        "cache_cells_counters": true,
        "cache_size_bytes": 4294967296
    }'

    yq e -i -o json \
        "del(.cells_db_config.cells_lru_size) | \
         .cells_db_config = $Cells_DB_Config | \
         .remp = $Remp_Config | \
         .states_cache_mode = \"Moderate\" | \
         .skip_saving_persistent_states =  false | \
         .restore_db = true | \
         .low_memory_mode = true" \
        ${R_CFG_DIR}/config.json

    # Info messages
    echo "${Tg_Warn_sign} ATTENTION: The node going to restart and may be out of sync for a few hours if DB needs repair! "
    "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "${Tg_Warn_sign} ATTENTION: The node going to restart and may be out of sync for a few hours if DB needs repair!" > /dev/null 2>&1

    # Clean catchain's garbage files
    Catchains_Dir="${R_DB_DIR}/catchains"
    find ${Catchains_Dir}/ -depth -type f \( -name "candidates*" -o -name "catchainreceiver*" \) -mtime +2 -exec rm -f {} \;
    find ${Catchains_Dir}/ -depth -type d \( -name "candidates*" -o -name "catchainreceiver*" \) -mtime +2 -exec rm -rf {} \;

    sudo service $ServiceName restart
    sleep 2
    if [[ -z "$(pgrep rnode)" ]];then
        echo "###-ERROR(line $LINENO): Node process not started!"
        "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "$Tg_SOS_sign ###-ERROR(line $LINENO): Node process not started!" > /dev/null 2>&1
        exit 1
    fi
    ${SCRIPT_DIR}/wait_for_sync.sh
fi
#===========================================================
# Check and show the Node version
Node_bin_commit="$(rnode -V | grep 'NODE git commit:' | awk '{print $5}')"
EverNode_Version="$(${NODE_BIN_DIR}/rnode -V | grep -i 'TON Node, version' | awk '{print $4}')"
NodeSupBlkVer="$(rnode -V | grep 'BLOCK_VERSION:' | awk '{print $2}')"
Console_Version="$(${NODE_BIN_DIR}/console -V | awk '{print $2}')"
TonosCLI_Version="$(${NODE_BIN_DIR}/tonos-cli -V | grep -i 'tonos_cli' | awk '{print $2}')"
echo "INFO: Node updated. Service restarted. Current versions: node ver: ${EverNode_Version} SupBlock: ${NodeSupBlkVer} node commit: ${Node_bin_commit}, console - ${Console_Version}, tonos-cli - ${TonosCLI_Version}"
"${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "$Tg_CheckMark INFO: Node updated. Service restarted. Current versions: node ver: ${EverNode_Version} node commit: ${Node_bin_commit}, console - ${Console_Version}, tonos-cli - ${TonosCLI_Version}" > /dev/null 2>&1
${SCRIPT_DIR}/take_part_in_elections.sh
${SCRIPT_DIR}/part_check.sh
${SCRIPT_DIR}/next_elect_set_time.sh

#===========================================================
#
# ${SCRIPT_DIR}/DB_Repair_Actions.sh
#
#===========================================================

echo "+++INFO: $(basename "$0") FINISHED $(date +%s) / $(date  +'%F %T %Z')"
echo "================================================================================================"

exit 0
