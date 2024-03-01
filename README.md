# Universal scripts set 
#### - Support both DePool and msig validations  
#### - Support both fift and solidity electors
#### - Tested on Ubuntu 22.04, CentOS Stream, Oracle Linux 9.x, FreeBSD 14 (for Linux - latest kernel preferable)

## Table of Contents
  - [0. System settings](#0-system-settings)
  - [1. Setting environment](#1-setting-environment)
  - [2. Build nodes](#2-build-nodes)
  - [3. Setup node and accounts](#3-setup-node-and-accounts)
  - [4. Start node and check syncronization](#4-start-node-and-check-syncronization)
  - [5. Deploy accounts](#5-deploy-accounts)
    - [5.1 Deploy validator msig with few custodians](#51-deploy-validator-msig-with-few-custodians)
    - [5.2 Setup and deploy DePool smartcontract](#52-setup-and-deploy-depool-smartcontract)
      - [5.2.1 Setup DePool parametrs](#521-setup-depool-parametrs)
      - [5.2.2 Send tokens to DePool account](#522-send-tokens-to-depool-account)
      - [5.2.3 Depoloy DePool contract](#523-depoloy-depool-contract)
    - [5.3 Deploy Tik account](#53-deploy-tik-account)
  - [6. Send stake to DePool](#6-send-stake-to-depool)
  - [7. Validations](#7-validations)
    - [7.1 Prepare for elections](#71-prepare-for-elections)
    - [7.2 Send stake to elector](#72-send-stake-to-elector)
    - [7.3 Check your participation in election](#73-check-your-participation-in-election)
    - [7.4 Set schedule in crontab](#74-set-schedule-in-crontab)
  - [8. Alert and Info](#8-alert-and-info)
    - [8.1 Alerts and info to telegram chat](#81-alerts-and-info-to-telegram-chat)
    - [8.2 Info scripts](#82-info-scripts)
      - [8.2.1 Check account balance](#821-check-account-balance)
      - [8.2.2 Show DePool info](#822-show-depool-info)

## 0. System settings
Login as root and do
```bash
mkdir -p ~/.ssh
echo "your ssh-rsa key" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```
Install **git**, **sudo**, **curl** and **bash** if it not installed (FreeBSD)

For FreeBSD make a link 
```bash  
ln -s /usr/local/bin/bash /bin/bash
```
Then add ordinary user with name as you wish (for example **"svt"**) and do
```bash
# FOR LINUX :
echo "svt  ALL=(ALL:ALL)  NOPASSWD:ALL" >> /etc/sudoers 
cp -r /root/.ssh /home/svt/
chown -R svt:svt /home/svt/.ssh
# =============================================
# For FreeBSD :
echo "svt  ALL=(ALL:ALL)  NOPASSWD:ALL" >> /usr/local/etc/sudoers
cp -r /root/.ssh /home/svt/
chown -R svt:svt /home/svt/.ssh
```
Setup your host name, timezone and firewall, update your system core and packs. 
Remember to open UDP port number defined in **ADNL_PORT** variable in 'env.sh' in your firewall. 

If you have separate disk for database, prepare it and mount to **/var/ton-work** (default). You can change it in `env.sh` in **TON_WORK_DIR** variable.  
  
Tune OS for best performance. At least set noatime for all partitions in fstab, and increase max number of files to 2M

<span style="color:red">**NB!! Double check if time sync is enabled.** It's critical for node operation.</span> 

## 1. Setting environment
First of all you have to set the follow environment variables for certain network at the beginning of **$HOME/main.evs.dev/scripts/env.sh**: 

```bash
export NETWORK_TYPE="main.ton.dev"      # can be main.* / net.* / fld.* / rustnet.* / rfld.*
export NODE_WC=0                        # Node WorkChain (for future rust network)

export FORCE_USE_DAPP=false             # set `true` For offnode works or to use DApp Server instead of use node's console to operate
export STAKE_MODE="depool"              # can be 'msig' or 'depool'
export MAX_FACTOR=3                     
...
export ADNL_PORT="49999"                # Open this UDP port in firewall
...
export DELAY_TIME=0                     # Delay time from the start of elections
```

And much more settings can be tuned in `env.sh`

## 2. Build nodes 
To build node run **./Nodes_Build.sh** from $HOME/main.evs.dev/scripts/ folder. 
This script will build all binaries needed and has 3 options:  
```bash
./Nodes_Build.sh        # build Rust node and all utilites
./Nodes_Build.sh rust   # build Rust node and tools and all it utilites
./Nodes_Build.sh dapp   # build Rust node for use in DApp server
```  
This script will build node, node console, utilites, tonos-cli, from the respective repositories from branches defined in `env.sh`. You can set repo & commit number in "# GIT addresses & commits " section in 'env.sh'

After successful build, all executable files will be placed to bin directory defined in **NODE_BIN_DIR** variable in 'env.sh'
The script also download smartcontracts and place it to folder defined in **ContractsDIR** variable in 'env.sh'. 

## 3. Setup node and accounts
All you needs to setup your node - run **./Setup.sh** script from $HOME/main.evs.dev/scripts/ folder. This script has no options and does the follow:
* remove old databases and logs if any
* create all needed dirs
* set proper url and endpoints in tonos-cli config file
* setup logrotate service
* setup new keys for node
* setup service **tonnode** to run node as service (you can change name in env.sh)
* generates 3 accounts and place files to $HOME/ton-keys (you can change it in env.sh)

Setup.sh generates 3 accounts files sets:  
* depool account files in **`$HOME/DPKeys_${HOSTNAME}`**
* validator msig (SafeCode) account files in **`$HOME/MSKeys_${HOSTNAME}`** with **3** custodians 
* Tik (SafeCode) account files in **`$HOME/MSKeys_Tik`** - Safe msig with 1 custodian for tik-tok depool
* finally, script place all files to **`$HOME/ton-keys/`**` if it hasn't same files already

If you have not any accounts before, you can use just generated accounts. If you already has your accounts files in **`$HOME/ton-keys/`**` it will NOT be replaced. 

## 4. Start node and check syncronization  
  
After Setup script successfully finished, you can start node by starting it service:
* **sudo service tonnode start** 

Then you can check node syncronizanion with the blockchain: 
```bash
./check_node_sync_status.sh
```
This script looped and will show you sync status every 1 min by default. It has 1 parameter - frequency of showing status in seconds:
```bash
./check_node_sync_status.sh 10      # show info every 10 secs
```
NB! On first start sync can start after some time, up to 30-60 mins, and can take a time depends of your server speed (mainly disk speed) and netkeyblock from which it is start syncing.  

<b><i>After TimeDiff became less 10, it means that masterchain is synced. But shardchains (threads) will continuing syncing. The scripts will be ready to full operate only after blockchain threads will be synced with local database.  
To  check full syncronisation run:
  
```bash
. ./env.sh
$CALL_RC -j -c "getstats" | jq '.sync_status'
```
When it return **"synchronization finished"** you can be shure that your DB is synced with the blockchain.</i></b>
If your node is present in validator set you can see status as validator:
```
{
  "sync_status": "synchronization_finished",
  "masterchainblocktime": 1692524874,
  "masterchainblocknumber": 30598675,
  "node_version": "0.55.35",
  "public_overlay_key_id": "<base64 public key stored in elector>",
  "timediff": 4,
  "shards_timediff": 4,
  "current_vset_p34_adnl_id": "base64 adnl id stored in elector",
  "in_current_vset_p34": true,
  "in_next_vset_p36": false,
  "last_applied_masterchain_block_id": {
    "shard": "-1:8000000000000000",
    "seq_no": 30598675,
    "rh": "429d760ae775662b0ae93b6364c1f8053679f584ef6b2b6d1836fe7f76d8376e",
    "fh": "ba4f930358e6dbe2c4d141e3d9f3d90cce934021a451c4c013b754e119b5a2b4"
  },
  "processed_workchain": "not specified",
  "validation_stats": {
    "-1:8000000000000000": "1 sec ago"
  },
  "collation_stats": {
    "-1:8000000000000000": "36 sec ago"
  },
  "tps_10": 3,
  "tps_300": 2,
  "validation_status": "Active"
}

```

## 5. Deploy accounts

### 5.1 Deploy validator msig with few custodians  

To deploy your validator main account, after receved tokens on it, use **`MS-Wallet_deploy.sh`** script. By default, it has 3 custodians and 2 is enought to sign a transaction  

```bash
MS-Wallet_deploy.sh $VALIDATOR_NAME Safe 3 2
```

### 5.2 Setup and deploy DePool smartcontract

#### 5.2.1 Setup DePool parametrs
First of all we to have set DePool parametrs for depool deploy script **`DP5_depool_deploy.sh`**  in **env.sh** in section **`# Depool deploy defaults`**
```bash
export ValidatorAssuranceT=100000       # Assurance in tokens
export MinStakeT=10                     # Min DePool assepted stake in tokens
export ParticipantRewardFraction=85     # In % participant share from reward
export BalanceThresholdT=20             # Min depool self balance to operate
export TIK_REPLANISH_AMOUNT=10          # If Tik acc balance less 2 tokens, It will be auto topup with this amount
```
These parameters cannot be changed after deploy the DePool.  
Exception is **ParticipantRewardFraction** it can be increased only, means - decrease validator commision.

All about Depool you can find in documentation - <a href="https://docs.ton.dev/86757ecb2/p/04040b-run-depool-v3" target="_blank">**Run DePool v3**</a>

#### 5.2.2 Send tokens to DePool account  
To send initial balance to DePool account use script **`transfer_amount.sh`**

```bash
./transfer_amount.sh $VALIDATOR_NAME depool 50 new
```
where:
* **`$VALIDATOR_NAME`** - file name of `${VALIDATOR_NAME}.addr` file with address of your msig
* **`depool`** - file name of `depool.addr` file with address of your DePool
* **50** - initial balance for deploy depool and it's proxies contracts
* **new** - set transaction flag **`bounce`** to false to tranfer tokens to undeployed address

next we have to sign the transaction by script **`Sign_Trans.sh`**
```bash
./Sign_Trans.sh
```
#### 5.2.3 Depoloy DePool contract
Now you can deploy the DePool contract by 
```bash
./DP5_depool_deploy.sh
```

### 5.3 Deploy Tik account
For tik-tok DePool action we use separate SafeCode msig account with 1 custodian and address in **`${KEYS_DIR}/Tik.addr`** file  
To deploy Tik smartcontract use the same script as for msig  
```bash
./transfer_amount.sh $VALIDATOR_NAME Tik 10 new
./Sign_Trans.sh
./MS-Wallet_deploy.sh Tik Safe 1 1
```

## 6. Send stake to DePool
Simple way to send stake to the depool is **ordinary stake**  to each round. Do follow before first elections for first round:
```bash
. ./env.sh
$CALL_TC depool --addr $(cat ${KEYS_DIR}/depool.addr) stake ordinary --wallet $(cat ${KEYS_DIR}/${VALIDATOR_NAME}.addr) --sign ${KEYS_DIR}/${VALIDATOR_NAME}.keys.json --value 30000
./Sign_Trans.sh
```
And do the same just after sent stake to the elector.  

More complex is to set **lock stake**. It will be automatically divide halfly for two rounds.
Before elections start do the follow:  
```bash
. ./env.sh
$CALL_TC depool --addr $(cat ${KEYS_DIR}/depool.addr) stake ordinary --wallet $(cat ${KEYS_DIR}/${VALIDATOR_NAME}.addr) --sign ${KEYS_DIR}/${VALIDATOR_NAME}.keys.json --value 30000
./Sign_Trans.sh
Donor_Addr=$(cat ${KEYS_DIR}/Donor.addr)  # should not be your validator address
$CALL_TC depool --addr $(cat ${KEYS_DIR}/depool.addr) donor vesting --wallet $(cat ${KEYS_DIR}/${VALIDATOR_NAME}.addr) --donor "$Donor_Addr" --sign ${KEYS_DIR}/${VALIDATOR_NAME}.keys.json
./Sign_Trans.sh 
$CALL_TC depool --addr $(cat ${KEYS_DIR}/depool.addr) stake lock --wallet $(cat ${KEYS_DIR}/Donor.addr) --total 365 --withdrawal 365 --beneficiary $(cat ${KEYS_DIR}/${VALIDATOR_NAME}.addr) --sign ${KEYS_DIR}/Donor.keys.json  --value 60000
./Sign_Trans.sh Donor
./prepare_elections.sh
# For remove your ordinary stake do
$CALL_TC depool --addr $(cat ${KEYS_DIR}/depool.addr) withdraw on --wallet $(cat ${KEYS_DIR}/${VALIDATOR_NAME}.addr) --sign ${KEYS_DIR}/${VALIDATOR_NAME}.keys.json
./Sign_Trans.sh
```
**$CALL_TC** - variable for invoke tonos-cli utility with parameters, predefined in `env.sh`
Full documentations for **tonos-cli** can be found here - <a href="https://github.com/tonlabs/tonos-cli#readme" target="_blank"> tonos-cli on github </a>

## 7. Validations
### 7.1 Prepare for elections
After a few minutes from elections start, we have to prepare the DePool by **`prepare_elections.sh`** script  
```bash
./prepare_elections.sh
```
In the case of depool validation mode, this script checks the balance of the Tik account and tops it up if it falls below 2 tokens. 
It also checks the depool's self-balance and the balances of both proxy accounts, topping them up if necessary.
Then, it sends a tik-tok transaction from Tik to DePool.

In the case of MSIG validation, the script checks for a stake to return in the elector and sends a request to return it if any is found.

### 7.2 Send stake to elector
```bash
./take_part_in_elections.sh
```
This script prepare all nesessary steps to prepare bid transaction for election and call **`Sign_Trans.sh`** to sign and send message to DePool with new keys for validating.

In case of MSIG validation the script send transaction with stake and keys to elector directly.

### 7.3 Check your participation in election
To check your participation status in currrent election use **`part_check.sh`**
During elections it will show your ADNL and stake amount. And between elections it will show your ADNL and % yours stake of total stake in the elector

### 7.4 Set schedule in crontab
To set all above scripts to run in time for further elections use script **`next_elect_set_time.sh`**`  
It has 2 main parametrs inside:  
```bash
DELAY_TIME=0        # Delay time from the start of elections
TIME_SHIFT=600      # Time between sequential scripts 
```
* **`DELAY_TIME`** - Time in seconds from a elections start and between scripts run
* **`DELAY_TIME`** - additional timeshift in seconds from the elections start  
**NB!**  crontab has not seconds precision, only minutes, so for proper use these numbers MUST be divisible by **60**

After run this script it set itself to crontab and will be run after all scripts in each elections

## 8. Alert and Info
### 8.1 Alerts and info to telegram chat 
You can setup your Telegram chat to receive alerts and info in file **`TlgChat.json`** like this:
```json
{
  "telegram_bot_token": "5xxxxxxx:Axxxxxxxxxxxxxxxxxxxxxx",
  "telegram_chat_id": "-100xxxxxxxxxx"
}
```
For monitoring timediff of your node you can run script **`tg_check_node_sync_status.s`** in tmux, for example:
```bash
cd $HOME/main.evs.dev/scripts
tmux kill-server  # kill all tmux sessions
tmux new -ds tg   # make new session named `tg`
tmux send -t tg.0 './tg_check_node_sync_status.sh &' ENTER  # run script in `tg` session
```
After that, if timediff will be more 100 secs or the node goes down you will receive message to you telegram channel.

**`part_check.sh`** script called from crontab will notify you about elections result to the same channel.

**`prepare_elections.sh`** and **`take_part_in_elections.sh`** will notify you if they will have some problems

### 8.2 Info scripts
#### 8.2.1 Check account balance

To check balance and state of contract, use
```bash
./balance_check.sh <addres or filename w/o extention in ton-keys folder>
```
without parameters the script will show state of validator msig.  

#### 8.2.2 Show DePool info
To see info and state of DePool contract, use
```bash
./dinfo.sh <addres or filename w/o extention in ton-keys folder>
```
without parameters the script will show state of validator's DePool.
You can give other depool address as script parametr in form as adrress (0:xxx) and as filename in `$HOME/ton-keys/` folder without .addr extention
