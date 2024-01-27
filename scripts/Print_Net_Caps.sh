#!/usr/bin/env bash
set -eE

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
echo "############################### Print net capabilities script ##################################"
echo "INFO: $(basename "$0") BEGIN $(date +%s) / $(date  +'%F %T %Z')"

# ===================================================
# Initialize script directory and source environment and function scripts
SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/functions.shinc"

#=================================================
# Print current time, environment info, and current network status
echo -e "\n${0##*/} Time Now: $(date  +'%F %T %Z')\n"
echo -e "$(DispEnvInfo)\n"
echo -e "$(Determine_Current_Network)\n"

#=================================================
# Get capabilities
DecodeCap=$1
declare -i NetCaps
if [[ -z "$DecodeCap" ]];then
    # Fetch capabilities from the network configuration using Everscale tools
    if $FORCE_USE_DAPP;then
        NetCaps=$(printf "%d" "0x$($CALL_TC -j getconfig 8 | jq -r '.capabilities' | cut -d 'x' -f 2)")
    else
        NetCaps=$($CALL_RC -jc 'getconfig 8'|jq -r '.p8.capabilities_dec')
    fi
else
    # Process the provided DecodeCap argument to handle both hex and decimal formats
    if [[ "$DecodeCap" =~ ^0x[0-9a-fA-F]+$ ]]; then
        # If the value starts with 0x, treat it as hexadecimal
        NetCaps=$((DecodeCap))
    elif [[ "$DecodeCap" =~ ^[0-9]+$ ]]; then
        # If the value consists only of numbers, treat it as decimal
        NetCaps=$DecodeCap
    else
        echo "###-ERROR: DecodeCap must be a number in decimal or hex (prefixed with 0x) format"
        echo "Usage: $(basename "$0") [DecodeCap]"
        exit 1
    fi
fi

#=================================================
# from https://github.com/tonlabs/ever-block/blob/593fdf5b1935b57400e1b72deb79c32e630f975c/src/config_params.rs#L354
#            0 constant CapNone                    = 0x000000000000,
#            1 constant CapIhrEnabled              = 0x000000000001,
#            2 constant CapCreateStatsEnabled      = 0x000000000002,
#            4 constant CapBounceMsgBody           = 0x000000000004,
#            8 constant CapReportVersion           = 0x000000000008,
#           16 constant CapSplitMergeTransactions  = 0x000000000010,
#           32 constant CapShortDequeue            = 0x000000000020,
#           64 constant CapMbppEnabled             = 0x000000000040,
#          128 constant CapFastStorageStat         = 0x000000000080,
#          256 constant CapInitCodeHash            = 0x000000000100,
#          512 constant CapOffHypercube            = 0x000000000200,
#         1024 constant CapMycode                  = 0x000000000400,
#         2048 constant CapSetLibCode              = 0x000000000800,
#         4096 constant CapFixTupleIndexBug        = 0x000000001000,
#         8192 constant CapRemp                    = 0x000000002000,
#        16384 constant CapDelections              = 0x000000004000,
#                       CapReserved
#        65536 constant CapFullBodyInBounced       = 0x000000010000,
#       131072 constant CapStorageFeeToTvm         = 0x000000020000,
#       262144 constant CapCopyleft                = 0x000000040000,
#       524288 constant CapIndexAccounts           = 0x000000080000,
#      1048576 constant CapDiff                    = 0x000000100000, // for GOSH
#      2097152 constant CapsTvmBugfixes2022        = 0x000000200000, // popsave, exception handler, loops
#      4194304 constant CapWorkchains              = 0x000000400000,
#      8388608 constant CapStcontNewFormat         = 0x000000800000, // support old format continuation serialization
#     16777216 constant CapFastStorageStatBugfix   = 0x000001000000, // calc cell datasize using fast storage stat
#     33554432 constant CapResolveMerkleCell       = 0x000002000000,
#     67108864 constant CapSignatureWithId         = 0x000004000000, // use some predefined id during signature check
#    134217728 constant CapBounceAfterFailedAction = 0x000008000000,
#    268435456 constant CapGroth16                 = 0x000010000000,
#    536870912 constant CapFeeInGasUnits           = 0x000020000000, // all fees in config are in gas units
#   1073741824 constant CapBigCells                = 0x000040000000,
#   2147483648 constant CapSuspendedList           = 0x000080000000,
#   4294967296 constant CapFastFinality            = 0x000100000000
#   8589934592 constant CapTvmV19                  = 0x000200000000, // TVM v1.9.x improvemements
#  17179869184 constant CapSmft                    = 0x000400000000,
#  34359738368 constant CapNoSplitOutQueue         = 0x000800000000, // Don't split out queue on shard splitting

#=================================================
# List of all capabilities with their decimal and hex values
# This section contains the declaration of capabilities and their corresponding values
CapsList=(CapIhrEnabled    \
CapCreateStatsEnabled      \
CapBounceMsgBody           \
CapReportVersion           \
CapSplitMergeTransactions  \
CapShortDequeue            \
CapMbppEnabled             \
CapFastStorageStat         \
CapInitCodeHash            \
CapOffHypercube            \
CapMycode                  \
CapSetLibCode              \
CapFixTupleIndexBug        \
CapRemp                    \
CapDelections              \
CapReserved                \
CapFullBodyInBounced       \
CapStorageFeeToTvm         \
CapCopyleft                \
CapIndexAccounts           \
CapDiff                    \
CapsTvmBugfixes2022        \
CapWorkchains              \
CapStcontNewFormat         \
CapFastStorageStatBugfix   \
CapResolveMerkleCell       \
CapSignatureWithId         \
CapBounceAfterFailedAction \
CapGroth16                 \
CapFeeInGasUnits           \
CapBigCells                \
CapSuspendedList           \
CapFastFinality            \
CapTvmV19                  \
CapSmft                    \
CapNoSplitOutQueue         \
)

# echo ${CapsList[@]}

declare -A DecCaps=(
[CapIhrEnabled]=1                       \
[CapCreateStatsEnabled]=2               \
[CapBounceMsgBody]=4                    \
[CapReportVersion]=8                    \
[CapSplitMergeTransactions]=16          \
[CapShortDequeue]=32                    \
[CapMbppEnabled]=64                     \
[CapFastStorageStat]=128                \
[CapInitCodeHash]=256                   \
[CapOffHypercube]=512                   \
[CapMycode]=1024                        \
[CapSetLibCode]=2048                    \
[CapFixTupleIndexBug]=4096              \
[CapRemp]=8192                          \
[CapDelections]=16384                   \
[CapReserved]=32768                     \
[CapFullBodyInBounced]=65536            \
[CapStorageFeeToTvm]=131072             \
[CapCopyleft]=262144                    \
[CapIndexAccounts]=524288               \
[CapDiff]=1048576                       \
[CapsTvmBugfixes2022]=2097152           \
[CapWorkchains]=4194304                 \
[CapStcontNewFormat]=8388608            \
[CapFastStorageStatBugfix]=16777216     \
[CapResolveMerkleCell]=33554432         \
[CapSignatureWithId]=67108864           \
[CapBounceAfterFailedAction]=134217728  \
[CapGroth16]=268435456                  \
[CapFeeInGasUnits]=536870912            \
[CapBigCells]=1073741824                \
[CapSuspendedList]=2147483648           \
[CapFastFinality]=4294967296            \
[CapTvmV19]=8589934592                  \
[CapSmft]=17179869184                   \
[CapNoSplitOutQueue]=34359738368        \
)

declare -A CapsHEX=(
[CapNone]="0x0000000000"
[CapIhrEnabled]="0x0000000001"
[CapCreateStatsEnabled]="0x0000000002"
[CapBounceMsgBody]="0x0000000004"
[CapReportVersion]="0x0000000008"
[CapSplitMergeTransactions]="0x0000000010"
[CapShortDequeue]="0x0000000020"
[CapMbppEnabled]="0x0000000040"
[CapFastStorageStat]="0x0000000080"
[CapInitCodeHash]="0x0000000100"
[CapOffHypercube]="0x0000000200"
[CapMycode]="0x0000000400"
[CapSetLibCode]="0x0000000800"
[CapFixTupleIndexBug]="0x0000001000"
[CapRemp]="0x0000002000"
[CapDelections]="0x0000004000"
[CapReserved]="0x0000008000"
[CapFullBodyInBounced]="0x0000010000"
[CapStorageFeeToTvm]="0x0000020000"
[CapCopyleft]="0x0000040000"
[CapIndexAccounts]="0x0000080000"
[CapDiff]="0x0000100000"
[CapsTvmBugfixes2022]="0x0000200000"
[CapWorkchains]="0x0000400000"
[CapStcontNewFormat]="0x0000800000"
[CapFastStorageStatBugfix]="0x0001000000"
[CapResolveMerkleCell]="0x0002000000"
[CapSignatureWithId]="0x0004000000"
[CapBounceAfterFailedAction]="0x0008000000"
[CapGroth16]="0x0010000000"
[CapFeeInGasUnits]="0x0020000000"
[CapBigCells]="0x0040000000"
[CapSuspendedList]="0x0080000000"
[CapFastFinality]="0x0100000000"
[CapTvmV19]="0x0200000000"
[CapSmft]="0x0400000000"
[CapNoSplitOutQueue]="0x0800000000"
)
# echo ${DecCaps[@]}

#=================================================
# Function to print a capability in a formatted manner
print_capability() {
    local cap_name=$1
    local cap_hex=${CapsHEX[$cap_name]}
    local cap_dec=${DecCaps[$cap_name]}
    printf '%26s  %10s  %11d\n' "$cap_name" "$cap_hex" "$cap_dec"
}

#=================================================
# Iterating through the capabilities list to check and print active capabilities
declare -i Cups_sum=0
for CurCup in "${CapsList[@]}"; do
    if [[ $((NetCaps & DecCaps[$CurCup])) -ne 0 ]]; then
        Cups_sum=$((Cups_sum + DecCaps[$CurCup]))
        print_capability "$CurCup"
    fi
done

echo "-------------------------------------------"
echo "Sum from net: $(printf 0x'%X' "$NetCaps") ($NetCaps) , Calc: $(printf 0x'%X' "$Cups_sum") ($Cups_sum)"
echo
echo "=================================================================================================="
exit 0
