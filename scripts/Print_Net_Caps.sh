#!/usr/bin/env bash
set -eE

# (C) Sergey Tyurin  2022-08-16 10:00:00

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
echo "############################### Print net capabilities script ##################################"
echo "INFO: $(basename "$0") BEGIN $(date +%s) / $(date  +'%F %T %Z')"
# ===================================================
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
#=================================================

if $FORCE_USE_DAPP;then
    declare -i NetCaps=$($CALL_TC -j getconfig 8|jq -r '.capabilities' | cut -d 'x' -f 2|tr "[:lower:]" "[:upper:]"| echo $(echo $(echo "obase=10; ibase=16; `cat`" | bc)))
else
    declare -i NetCaps=$($CALL_RC -jc 'getconfig 8'|jq -r '.p8.capabilities_dec')
fi

# from https://github.com/tonlabs/ton-labs-block/blob/master/src/config_params.rs#L336
#      0 constant CapNone                   = 0x000000,
#      1 constant CapIhrEnabled             = 0x000001,
#      2 constant CapCreateStatsEnabled     = 0x000002,
#      4 constant CapBounceMsgBody          = 0x000004,
#      8 constant CapReportVersion          = 0x000008,
#     16 constant CapSplitMergeTransactions = 0x000010,
#     32 constant CapShortDequeue           = 0x000020,
#     64 constant CapMbppEnabled            = 0x000040,
#    128 constant CapFastStorageStat        = 0x000080,
#    256 constant CapInitCodeHash           = 0x000100,
#    512 constant CapOffHypercube           = 0x000200,
#   1024 constant CapMycode                 = 0x000400,
#   2048 constant CapSetLibCode             = 0x000800,
#   4096 constant CapFixTupleIndexBug       = 0x001000,
#   8192 constant CapRemp                   = 0x002000,
#  16384 constant CapDelections             = 0x004000,
#  32768 constant CapFullBodyInBounced      = 0x010000,
#  65536 constant CapStorageFeeToTvm        = 0x020000,
# 131072 constant CapCopyleft               = 0x040000,
# 262144 constant CapIndexAccounts          = 0x080000,
# 524288 constant CapDiff                   = 0x100000, // for GOSH

# CapNone                   \
# CapIhrEnabled             \
# CapCreateStatsEnabled     \
# CapBounceMsgBody          \
# CapReportVersion          \
# CapSplitMergeTransactions \
# CapShortDequeue           \
# CapMbppEnabled            \
# CapFastStorageStat        \
# CapInitCodeHash           \
# CapOffHypercube           \
# CapMycode                 \
# CapSetLibCode             \
# CapFixTupleIndexBug       \
# CapRemp                   \
# CapDelections             \
# CapFullBodyInBounced      \
# CapStorageFeeToTvm        \
# CapCopyleft               \
# CapIndexAccounts          \
# CapDiff 

# CapNone CapIhrEnabled CapCreateStatsEnabled CapBounceMsgBody CapReportVersion CapSplitMergeTransactions \
# CapShortDequeue CapMbppEnabled CapFastStorageStat CapInitCodeHash CapOffHypercube  CapMycode CapSetLibCode \
# CapFixTupleIndexBug CapRemp CapDelections CapFullBodyInBounced CapStorageFeeToTvm CapCopyleft CapIndexAccounts CapDiff                  

CapsList=(CapIhrEnabled   \
CapCreateStatsEnabled     \
CapBounceMsgBody          \
CapReportVersion          \
CapSplitMergeTransactions \
CapShortDequeue           \
CapMbppEnabled            \
CapFastStorageStat        \
CapInitCodeHash           \
CapOffHypercube           \
CapMycode                 \
CapSetLibCode             \
CapFixTupleIndexBug       \
CapRemp                   \
CapDelections             \
CapFullBodyInBounced      \
CapStorageFeeToTvm        \
CapCopyleft               \
CapIndexAccounts          \
CapDiff 
)

# echo ${CapsList[@]}

declare -A DecCaps=(
[CapIhrEnabled]=1              \
[CapCreateStatsEnabled]=2      \
[CapBounceMsgBody]=4           \
[CapReportVersion]=8           \
[CapSplitMergeTransactions]=16 \
[CapShortDequeue]=32           \
[CapMbppEnabled]=64            \
[CapFastStorageStat]=128       \
[CapInitCodeHash]=256          \
[CapOffHypercube]=512          \
[CapMycode]=1024               \
[CapSetLibCode]=2048           \
[CapFixTupleIndexBug]=4096     \
[CapRemp]=8192                 \
[CapDelections]=16384          \
[CapFullBodyInBounced]=32768   \
[CapStorageFeeToTvm]=65536     \
[CapCopyleft]=131072           \
[CapIndexAccounts]=262144      \
[CapDiff]=524288 
)

# echo ${DecCaps[@]}

declare -i Cups_sum=0
for CurCup in "${CapsList[@]}"; do
    if [[ $(($NetCaps & ${DecCaps[$CurCup]})) -ne 0 ]];then
        Cups_sum=$(($Cups_sum + ${DecCaps[$CurCup]}))
        echo "$CurCup ${DecCaps[$CurCup]}"
    fi
done
echo "-------------------------------------------"
echo "Sum from net: $NetCaps, Calc: $Cups_sum"
echo
echo "=================================================================================================="
exit 0
