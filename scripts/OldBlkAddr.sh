#!/usr/bin/env bash

# (C) Sergey Tyurin  2022-06-19 11:00:00

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
echo "############################# Check Validators Block Version ###################################"
echo "+++INFO: $(basename "$0") BEGIN $(date +%s) / $(date  +'%F %T %Z')"

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/functions.shinc"

function show_usage(){
echo
echo " Use: $0 <ValAddrList_File> <HistHours>"
echo " All fields required!"
echo
exit 0
}
[[ $# -le 1 ]] && show_usage

#================================================================

ValAddrList_File="$1"
HistHours=$2

if [[ ! -f $ValAddrList_File ]];then
    echo "###-ERROR(line $LINENO): File with validators info not found!"
    exit 1
fi

# Check file with to correspond to the current elections ID
ElectionsCycle_ID=${ValAddrList_File%%_*}
CurrElectionsCycle_ID=$($CALL_RC -jc 'getconfig 34'|jq -r .p34.utime_since)
[[ $ElectionsCycle_ID -ne $CurrElectionsCycle_ID ]] && echo "###-ERROR: File with validators info ($ElectionsCycle_ID) not correspond to the current elections ID($CurrElectionsCycle_ID)!" && exit 1   
echo "ElectionsCycle_ID: $ElectionsCycle_ID"

############################
# token for ipinfo.io should be set in env.sh
# ipi_token=""
: ${ipi_token:?"ERROR: token for ipinfo.io should be set here or in env.sh"}
############################

declare -ai Blk_Ver_List=($Node_Blk_Min_Ver $((Node_Blk_Min_Ver -1)) $((Node_Blk_Min_Ver -2)) $((Node_Blk_Min_Ver -3)) $((Node_Blk_Min_Ver -4)) $((Node_Blk_Min_Ver -5)))
echo "Block versions to check: ${Blk_Ver_List[*]}"
declare -ai Blk_Ver_Cntr=(0 0 0)

ElectionsCycle_ID=${ValAddrList_File%%_*}

ValAddrList_json="$(cat "${ValAddrList_File}"|jq 'to_entries')"
declare -i NodesQty=$(echo "${ValAddrList_json}"|jq '.|length')

Time_Inerval=$((3600 * HistHours))
Time_Start=$(($(date +%s) - Time_Inerval))

declare -i NoBlockNodes=0
declare -i OldBlockNodes=0
declare -i Custler_CU=0
declare -i Custler_MED=0
NoBlockNodesList=""

for (( i=0; i < NodesQty; i++ ));do
    CurPub=$(echo "${ValAddrList_json}"|jq -r ".[$i].value.pubkey")
    CurrNodeBlkVer=`curl -sS -X POST -g -H "$Auth_key_Head" -H "Content-Type: application/json" "${DApp_URL}/graphql" -d \
    '{"query": "query {blocks(filter: { gen_utime: {gt: '$Time_Start'}, created_by: {eq: \"'$CurPub'\"} }limit: 1) {id, gen_software_version} }"}' \
    |jq '.data.blocks[0].gen_software_version'`
    # echo "Pubkey: $CurPub   Blk: $CurrNodeBlkVer"
    Hoster=""
    ADNL_hex=$(echo "${ValAddrList_json}"|jq ".[$i].value.ADNL")
    if [[ -n "$ADNL_hex" ]];then
        ADNL_B64="$(echo "$ADNL_hex" | xxd -r -p | base64)"
        IP_Port="$(timeout 30 ${HOME}/bin/adnl_resolve $ADNL_B64 ./common/config/ton-global.config.json 2>/dev/null)"
        [[ -n $(echo "$IP_Port" | grep -i 'error') ]] && echo "$IP_Port"
        IP_Port="$(echo "$IP_Port" | grep 'Found' | awk '{print $2}')"
        [[ -n "$IP_Port" ]] && Hoster="$(curl "https://ipinfo.io/${IP_Port%%:*}/json?token=${ipi_token}" 2>/dev/null|jq '.org , .city , .country'|tr -d "\n")"
        [[ "$(echo "$IP_Port"|awk -F':' '{print $2}')" == "48888" ]] && ((Custler_CU+=1))
        [[ "$(echo "$IP_Port"|awk -F':' '{print $2}')" == "49999" ]] && ((Custler_MED+=1))
    fi 
    
    Stake_nt=$(echo "${ValAddrList_json}"|jq -r ".[$i].value.stake_nt")
    Stake_tok=$(echo $((Stake_nt / 1000000000))|LC_ALL=en_US.UTF-8 xargs printf "%'.f\n")
    
    if [[ $CurrNodeBlkVer -lt $((Blk_Ver_List[0])) ]] && [[ $CurrNodeBlkVer -gt 0 ]];then
        ((OldBlockNodes+=1))
        echo "------------------------------------------"
        echo "$OldBlockNodes BlkVer: $CurrNodeBlkVer Stake: $Stake_tok"
        echo "MSIG:   $(echo "${ValAddrList_json}"|jq -r ".[$i].value.MSIG") "
        echo "DePool: $(echo "${ValAddrList_json}"|jq -r ".[$i].value.depool")"
        echo "ADNL:   $ADNL_hex"
        echo "IP:port = $IP_Port  $Hoster"
    fi
    
    if [[ $CurrNodeBlkVer -eq 0 ]];then
        ((NoBlockNodes+=1))
        NoBlockNodesList+="------------------------------------------\n"
        NoBlockNodesList+="$NoBlockNodes BlkVer: $CurrNodeBlkVer Stake: $Stake_tok \n"
        NoBlockNodesList+="MSIG:   $(echo "${ValAddrList_json}"|jq -r ".[$i].value.MSIG")  \n"
        NoBlockNodesList+="DePool: $(echo "${ValAddrList_json}"|jq -r ".[$i].value.depool") \n"
        NoBlockNodesList+="ADNL:   $ADNL_hex \n"
        NoBlockNodesList+="IP:port = $IP_Port  $Hoster \n"
    fi
    
    for ((bv=0; bv < ${#Blk_Ver_List[*]}; bv++)) do
        [[ $CurrNodeBlkVer -eq ${Blk_Ver_List[bv]} ]] && (( Blk_Ver_Cntr[bv]++))
    done 

done
echo "------------------------------------------"
echo
echo "Summary for last $((Time_Inerval / 3600)) hours since $(TD_unix2human $Time_Start):"
echo "Total nodes participated in elections: $NodesQty"

for ((bv=0; bv < ${#Blk_Ver_List[*]}; bv++)) do
    echo " Nodes blk ver ${Blk_Ver_List[bv]}: ${Blk_Ver_Cntr[bv]}"
done 

echo " custler.uninode Nodes: $Custler_CU"
echo " main.evs.dev    Nodes: $Custler_MED"

echo "Total nodes in round $ElectionsCycle_ID / $(TD_unix2human $ElectionsCycle_ID) : $NodesQty"
echo "Nodes with old blocks =         $OldBlockNodes"
echo "Nodes which not made any blocks = $NoBlockNodes"
echo

echo "Nodes not made any blocks (not in MC or WC) in current round $ElectionsCycle_ID / $(TD_unix2human $ElectionsCycle_ID):  "
echo -e $NoBlockNodesList

echo "------------------------------------------"

echo
echo "+++INFO: $(basename "$0") FINISHED $(date +%s) / $(date)"
echo "================================================================================================"

exit 0

################################################################################################
FOR b IN blocks
SORT b.gen_utime DESC
FILTER b.gen_utime > 1655613568 && b.gen_software_version < 25
COLLECT g = b.gen_software_version, c = b.created_by
RETURN { g, c }
#========================================
query BLK_ver_by_pubkey {
    blocks(
    filter:{
      gen_utime:{gt: }
      created_by:{eq: ""}
      #gen_software_version:{eq: 22}
      #workchain_id:{eq: 0}
     }
    limit: 10
  ){
    id
    gen_utime_string
    gen_software_version
 		created_by
    #signatures {signatures: }
    workchain_id
    shard
    # account_blocks
   }
}
#========================================
