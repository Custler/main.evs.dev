#!/usr/bin/env bash

# (C) Sergey Tyurin  2021-10-19 10:00:00

# Disclaimer
##################################################################################################################
# You running this script/function means you will not blame the author(s).
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
#

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/functions.shinc"

#=================================================
echo
echo "${0##*/} Time Now: $(date  +'%F %T %Z')"
echo -e "$(DispEnvInfo)"
echo
echo -e "$(Determine_Current_Network)"
echo

ACCOUNT=$1
if [[ -z $ACCOUNT ]];then
    MY_ACCOUNT=`cat "${KEYS_DIR}/${VALIDATOR_NAME}.addr"`
    if [[ -z $MY_ACCOUNT ]];then
        echo " Can't find ${KEYS_DIR}/${VALIDATOR_NAME}.addr"
        exit 1
    else
        ACCOUNT=$MY_ACCOUNT
    fi
else
    acc_fmt="$(echo "$ACCOUNT" |  awk -F ':' '{print $2}')"
    [[ -z $acc_fmt ]] && ACCOUNT=`cat "${KEYS_DIR}/${ACCOUNT}.addr"`
fi
echo "Account: $ACCOUNT"
acc_wc=${ACCOUNT%%:*}
NODE_WC="0"
if [[ "${NODE_WC}" != "${acc_wc}" ]] && [[ "${acc_wc}" != "-1" ]];then
    echo -e "${BoldText}${YellowBack}WARNING: You are ask account info from a other workchain than the node is. Result may be wrong!${NormText}"
fi
ACCOUNT_INFO="$(Get_Account_Info $ACCOUNT)"
ACC_STATUS=`echo $ACCOUNT_INFO |awk '{print $1}'`
if [[ "$ACC_STATUS" == "None" ]];then
    echo -e "${BoldText}${RedBack}Account does not exist! (no tokens, no code, nothing)${NormText}"
    echo "=================================================================================================="
    exit 0
fi
[[ "$ACC_STATUS" == "Uninit" ]] && ACC_STATUS="${BoldText}${YellowBack}Uninit${NormText}" || ACC_STATUS="${BoldText}${GreeBack}Deployed and Active${NormText}"

AMOUNT=`echo "$ACCOUNT_INFO" |awk '{print $2}'`
ACC_LAST_OP_TIME=`echo "$ACCOUNT_INFO" | gawk '{ print strftime("%Y-%m-%d %H:%M:%S", $3)}'`

echo -e "Status: $ACC_STATUS"
echo "Has balance : $(echo "scale=3; $((AMOUNT)) / 1000000000" | $CALL_BC) tokens"
echo "Last operation time: $ACC_LAST_OP_TIME"
if [[ "$(echo $ACCOUNT_INFO |awk '{print $1}')" == "Active" ]];then
    Custodians="$(Get_Account_Custodians_Info $ACCOUNT)"
    echo "Total custodians: $(echo $Custodians|awk '{print $1}'); Required to confirm: $(echo $Custodians|awk '{print $2}')"
fi

echo "=================================================================================================="
exit 0
