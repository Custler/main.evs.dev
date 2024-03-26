#!/usr/bin/env bash

# (C) Sergey Tyurin  2024-03-19 13:00:00

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

# usage: tg-check_node_sync_status.sh [T - timeout sec] [alarm to tg if time > N]

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/functions.shinc"

echo
echo -e "$(Determine_Current_Network)"
echo -e "$(DispEnvInfo)"
echo

SLEEP_TIMEOUT=$1
SLEEP_TIMEOUT=${SLEEP_TIMEOUT:="60"}
ALARM_TIME_DIFF=$2
ALARM_TIME_DIFF=${ALARM_TIME_DIFF:=100}
Current_Net="${NETWORK_TYPE%%.*}"
RC_OUTPUT=$($CALL_RC -j -c "getstats" 2>&1 | cat)
NODE_WC="$(echo "${RC_OUTPUT}"| grep 'processed workchain'|awk '{print $3}'|tr -d ',')"
[[ "${NODE_WC}" == "masterchain" ]] && NODE_WC="-1"

while(true)
do
    TIME_DIFF=$(Get_TimeDiff)

    if [[ "$TIME_DIFF" == "Node Down" ]];then
        echo "${Current_Net}:${NODE_WC} Time: $(date +'%F %T %Z') ###-ALARM! NODE IS DOWN or UNRESPONSIVE." | tee -a ${NODE_LOGS_ARCH}/time-diff.log
        # "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "ALARM! NODE IS DOWN." &> /dev/null
        sleep $SLEEP_TIMEOUT
        continue
    fi
    if [[ "$TIME_DIFF" == "Error" ]];then
        echo "${Current_Net}:${NODE_WC} Time: $(date +'%F %T %Z') ###-ALARM! NODE return ERROR." | tee -a ${NODE_LOGS_ARCH}/time-diff.log
        # "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "ALARM! NODE return ERROR." &> /dev/null
        sleep $SLEEP_TIMEOUT
        continue
    fi

    if [[ "$TIME_DIFF" == "db_broken" ]];then
        echo "${Current_Net} Time: $(date +'%F %T %Z') ###-ALARM! node DB is BROKEN!" | tee -a ${NODE_LOGS_ARCH}/time-diff.log
        "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "ALARM! node DB is BROKEN!" &> /dev/null
        sleep $SLEEP_TIMEOUT
        continue
    fi

    STATUS=$(echo $TIME_DIFF|awk '{print $3}')
    if [[ "$STATUS" != "synchronization_by_blocks" ]] && [[ "$STATUS" != "synchronization_finished" ]];then
        echo "${Current_Net}:${NODE_WC} Time: $(date +'%F %T %Z') --- Current node status: $TIME_DIFF" | tee -a ${NODE_LOGS_ARCH}/time-diff.log
    else
        MC_TIME_DIFF=$(echo $TIME_DIFF|awk '{print $1}')
        SH_TIME_DIFF=$(echo $TIME_DIFF|awk '{print $2}')
        VALIDATION=$(echo $TIME_DIFF|awk '{print $4}')
        echo "${Current_Net}:${NODE_WC} Time: $(date +'%F %T %Z') TimeDiffs: MC - $MC_TIME_DIFF ; WC - $SH_TIME_DIFF ; VAL- $VALIDATION" | tee -a ${NODE_LOGS_ARCH}/time-diff.log
    fi
    # if [[ $MC_TIME_DIFF -gt $ALARM_TIME_DIFF ]] || [[ $SH_TIME_DIFF -gt $ALARM_TIME_DIFF ]];then
    #     "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "${Tg_Warn_sign} ALARM! NODE out of sync. TimeDiffs: MC - $MC_TIME_DIFF ; WC - $SH_TIME_DIFF" &> /dev/null
    # fi
    sleep $SLEEP_TIMEOUT
done

exit 0

#==========================================
# https://github.com/tonlabs/ever-node/blob/e1c321bf3aef765554c3caa43e0bd417bb4ba14d/src/network/control.rs#L183

