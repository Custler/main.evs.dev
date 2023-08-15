function top_app_account () {
    Account_Addr="$1"
    TopUpSum="$2"
    # -------------------------------------------
    # Check that the account is ready and there are enough tokens on it
    Acc_Info="$(Get_Account_Info $Account_Addr)"
    Acc_Status="$(echo $Acc_Info | awk '{print $1}')"
    Old_LastTrans_Time_Unix=$(echo $Acc_Info | awk '{print $3}')
    
    [[ "$Acc_Status" == "None" ]] && echoerr "###-ERROR(${FUNCNAME[0]} line $LINENO): func top_app_account: Account does not exist! (no tokens, no code, nothing" && return 1
    [[ "$Acc_Status" == "Uninit" ]] && echoerr "###-ERROR(${FUNCNAME[0]} line $LINENO): func top_app_account: Account Uninited" && return 1
    
    # -------------------------------------------
    # Make BOC file to send
    Custodians="$(Get_Account_Custodians_Info "$Validator_addr")"
    Val_Confirm_QTY=$(echo $Custodians|awk '{print $2}')
    TOPUP_BOC_File="${ELECTIONS_WORK_DIR}/${elections_id}_topup.boc"
    rm -f "${TOPUP_BOC_File}"

    TC_OUTPUT="$($CALL_TC message --raw --output ${TOPUP_BOC_File} \
    --sign "${KEYS_DIR}/${VALIDATOR_NAME}.keys.json" \
    --abi "${SafeC_Wallet_ABI}" \
    ${Validator_addr} submitTransaction \
    "{\"dest\":\"${Account_Addr}\",\"value\":$((TopUpSum)),\"bounce\":true,\"allBalance\":false,\"payload\":\"\"}" \
    --lifetime 600)"

    if [[ "$(echo $TC_OUTPUT | grep -i 'error')" ]];then
        echo "###-ERROR(${FUNCNAME[0]} line $LINENO): Error while make topup message boc : ${TC_OUTPUT}"
        "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server: DePool prepare:" \
            "${Tg_SOS_sign}###-ERROR(${FUNCNAME[0]} line $LINENO): Error while make topup message boc : ${TC_OUTPUT}"
    fi

    if [[ ! -f ${TOPUP_BOC_File} ]];then
        echo "###-ERROR(${FUNCNAME[0]} line $LINENO): Failed to make BOC file ${TOPUP_BOC_File}."
        "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server: DePool prepare:" \
            "${Tg_SOS_sign}###-ERROR(${FUNCNAME[0]} line $LINENO): Failed to make BOC file ${TOPUP_BOC_File} for topup account."
    fi
    
    # -------------------------------------------
    Trans_List="$(Get_MSIG_Trans_List ${Validator_addr})"
    Before_Trans_QTY=$(echo "$Trans_List" | jq -r ".transactions|length")
    Before_Trans_QTY=$((Before_Trans_QTY))
    if [[ $Before_Trans_QTY -ne 0 ]];then
        echo "+++WARNING(${FUNCNAME[0]} line $LINENO): You have $Before_Trans_QTY unsigned transactions already."
        "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server: DePool prepare:" \
            "${Tg_Warn_sign} WARNING(${FUNCNAME[0]} line $LINENO): You have $Before_Trans_QTY unsigned transactions already."
    fi

    # -------------------------------------------
    for (( i=1; i <= 5; i++ )); do
        result=$(Send_File_To_BC "${TOPUP_BOC_File}")
        if [[ "$result" == "failed" ]]; then
            echo " FAIL"
            echo "Now sleep $LC_Send_MSG_Timeout secs and will try again.."
            echo "--------------"
            sleep $LC_Send_MSG_Timeout
            continue
        fi
       if [[ $Val_Confirm_QTY -le 1 ]];then
            Acc_Info="$(Get_Account_Info $Validator_addr)"
            Curr_LastTrans_Time_Unix=$(echo $Acc_Info |awk '{print $3}')
            if [[ $Curr_LastTrans_Time_Unix -gt $Old_LastTrans_Time_Unix ]];then
                echo -e "INFO: successfully sent $TRANSF_AMOUNT tokens."
                break
            fi
       fi
        Trans_List="$(Get_MSIG_Trans_List ${Validator_addr})"
        Trans_QTY=$(echo "$Trans_List" | jq -r ".transactions|length")
        Trans_QTY=$((Trans_QTY))
        if [[ $Trans_QTY -gt $Before_Trans_QTY ]] && [[ $Val_Confirm_QTY -gt 1 ]];then
            Last_Trans_ID=$(echo "$Trans_List" | jq -r .transactions[$((Trans_QTY - 1))].id)
            echo -e "INFO: successfully created transaction # $Last_Trans_ID"
            break
       fi
    done
    if [[ $Val_Confirm_QTY -gt 1 ]];then
        "${SCRIPT_DIR}/Sign_Trans.sh" ${VALIDATOR_NAME} $Last_Trans_ID | tee -a "${ELECTIONS_WORK_DIR}/${elections_id}.log"
    fi
    return 0
}
