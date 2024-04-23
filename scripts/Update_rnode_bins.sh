#!/usr/bin/env bash
SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

./Nodes_Build.sh

OS_SYSTEM=`uname -s`

if [[ "$OS_SYSTEM" == "Linux" ]];then
    sudo service $ServiceName stop
else
    service $ServiceName stop
fi

sleep 10

if [[ "$OS_SYSTEM" == "Linux" ]];then
    sudo service $ServiceName start
else
    service $ServiceName start
fi

exit 0
