#!/usr/bin/env bash
set -eE

# (C) Sergey Tyurin  2024-04-22 18:00:00

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

# All generated executables will be placed in the $NODE_BIN_DIR folder.
# Options:
#  rust - build rust node with utils
#  dapp - build rust node with utils for DApp server. 

BUILD_STRT_TIME=$(date +%s)

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"

echo
echo "################################### Everscale nodes build script ###################################"
echo "+++INFO: $(basename "$0") BEGIN $(date +%s) / $(date)"
echo "INFO from env: Network: $NETWORK_TYPE; WC: $NODE_WC; Elector: $ELECTOR_TYPE; Staking mode: $STAKE_MODE; Access method: $(if $FORCE_USE_DAPP;then echo "DApp"; else  echo "console"; fi )"

BackUP_Time="$(date +%Y-%m-%d_%H-%M-%S)"

case "$1" in
    rust)
        RUST_NODE_BUILD=true
        DAPP_NODE_BUILD=false
        echo "---INFO: Will build particular node "
        ;;
    dapp)
        RUST_NODE_BUILD=true
        DAPP_NODE_BUILD=true
        if [[ -z "$RNODE_FEATURES" ]];then
            RNODE_FEATURES="external_db,statsd"
        else
            RNODE_FEATURES="${RNODE_FEATURES},external_db,statsd"
        fi
        echo "---INFO: Will build node for DApp"
        ;;
    *)
        RUST_NODE_BUILD=true
        DAPP_NODE_BUILD=false
        echo "---INFO: Will build particular node "
        ;;
esac

[[ ! -d $NODE_BIN_DIR ]] && mkdir -p $NODE_BIN_DIR

#=====================================================
# Packages set for different OSes
PKGS_FreeBSD="git mc jq vim 7-zip libtool perl5 automake llvm-devel gmake wget gawk base64 cmake curl gperf openssl lzlib sysinfo tmux rsync logrotate zstd pkgconf python google-perftools"
PKGS_CentOS="git  mc jq vim bc p7zip curl wget libtool logrotate openssl-devel clang llvm-devel cmake gperf gawk tmux rsync zlib zlib-devel bzip2 bzip2-devel lz4-devel libzstd-devel gperftools gperftools-devel"
PKGS_Ubuntu="git  mc jq vim bc p7zip-full curl build-essential libssl-dev automake libtool clang llvm-dev cmake tmux rsync gawk gperf libz-dev pkg-config zlib1g-dev libzstd-dev libgoogle-perftools-dev"
PKGS_OL9UEK="git  mc jq vim bc p7zip curl wget libtool logrotate openssl-devel clang llvm-devel cmake gperf gawk tmux rsync zlib zlib-devel bzip2 bzip2-devel lz4-devel libzstd-devel libunwind libunwind-devel"

PKG_MNGR_FreeBSD="sudo pkg"
PKG_MNGR_CentOS="sudo dnf"
PKG_MNGR_Ubuntu="sudo apt"
FEXEC_FLG="-executable"

#=====================================================
# Detect OS and set packages
OS_SYSTEM=`uname -s`
if [[ "$OS_SYSTEM" == "Linux" ]];then
    OS_SYSTEM="$(hostnamectl |grep 'Operating System'|awk '{print $3}')"

elif [[ ! "$OS_SYSTEM" == "FreeBSD" ]];then
    echo
    echo "###-ERROR(line $LINENO): Unknown or unsupported OS. Can't continue."
    echo
    exit 1
fi
# Get Latest yq download url
# curl -sS -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/mikefarah/yq/releases/latest | grep '/yq_linux_amd64' | head -n 1 | awk '{print $2}'
# curl -sS -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.assets[]|select(.name == "yq_linux_amd64")|.browser_download_url'
YQ_API_RESPONCE="$(curl -sS -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/mikefarah/yq/releases/latest)"
YQ_LATEST_URL=""
if [[ -z $(echo "$YQ_API_RESPONCE" | jq '.message'|grep 'rate limit exceeded') ]];then
    YQ_LATEST_URL="$(echo "$YQ_API_RESPONCE" | jq -r '.assets[]|select(.name == "yq_linux_amd64")|.browser_download_url')"
fi
echo -e "\nYQ Latest URL for Linux: ${YQ_LATEST_URL}\n"
#=====================================================
# Set packages set & manager according to OS
case "$OS_SYSTEM" in
    FreeBSD)
        export ZSTD_LIB_DIR=/usr/local/lib
        PKGs_SET=$PKGS_FreeBSD
        PKG_MNGR=$PKG_MNGR_FreeBSD
        $PKG_MNGR update -f
        $PKG_MNGR upgrade -y
        FEXEC_FLG="-perm +111"
        if [[ -n $YQ_LATEST_URL ]];then
            YQ_LATEST_URL="$(echo "$YQ_API_RESPONCE" | jq -r '.assets[]|select(.name == "yq_freebsd_amd64")|.browser_download_url')"
            sudo wget "$YQ_LATEST_URL" -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
        fi
        ;;
    CentOS)
        export ZSTD_LIB_DIR=/usr/lib64
        PKGs_SET=$PKGS_CentOS
        PKG_MNGR=$PKG_MNGR_CentOS
        $PKG_MNGR -y update --allowerasing
        $PKG_MNGR group install -y "Development Tools"
        $PKG_MNGR config-manager --set-enabled powertools 
        $PKG_MNGR --enablerepo=extras install -y epel-release
        [[ -n $YQ_LATEST_URL ]] && sudo wget "$YQ_LATEST_URL" -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
        sudo systemctl daemon-reload
        ;;
    Oracle)
        export ZSTD_LIB_DIR=/usr/lib64
        PKGs_SET=$PKGS_CentOS
        PKG_MNGR=$PKG_MNGR_CentOS
        $PKG_MNGR -y update --allowerasing
        $PKG_MNGR group install -y "Development Tools"
        if [[ -n "$(cat /etc/os-release |grep 'VERSION_ID="9.')" ]];then
            PKGs_SET=$PKGS_OL9UEK
            $PKG_MNGR config-manager --set-enabled ol9_codeready_builder
            $PKG_MNGR install -y oracle-epel-release-el9
        else 
            $PKG_MNGR config-manager --set-enabled ol8_codeready_builder
            $PKG_MNGR install -y oracle-epel-release-el8
        fi
        [[ -n $YQ_LATEST_URL ]] && sudo wget "$YQ_LATEST_URL" -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
        sudo systemctl daemon-reload
        ;;
    Fedora|Red)
        export ZSTD_LIB_DIR=/usr/lib64
        PKGs_SET=$PKGS_CentOS
        PKG_MNGR=$PKG_MNGR_CentOS
        $PKG_MNGR -y update --allowerasing
        $PKG_MNGR group install -y "Development Tools"
        [[ -n $YQ_LATEST_URL ]] && sudo wget "$YQ_LATEST_URL" -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
        sudo systemctl daemon-reload
        ;;
    Ubuntu|Debian)
        export ZSTD_LIB_DIR=/usr/lib/x86_64-linux-gnu
        PKGs_SET=$PKGS_Ubuntu
        PKG_MNGR=$PKG_MNGR_Ubuntu
        $PKG_MNGR install -y software-properties-common
        sudo add-apt-repository -y ppa:ubuntu-toolchain-r/ppa
        [[ -n $YQ_LATEST_URL ]] && sudo wget "$YQ_LATEST_URL" -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
        sudo systemctl daemon-reload
        ;;
    *)
        echo
        echo "###-ERROR(line $LINENO): Unknown or unsupported OS. Can't continue."
        echo
        exit 1
        ;;
esac

#=====================================================
# Install packages
echo
echo '################################################'
echo "---INFO: Install packages ... "
$PKG_MNGR install -y $PKGs_SET

if [[ -n "$(cat /etc/os-release |grep 'PRETTY_NAME="Oracle Linux Server 9')" ]] && [[ ! -d "/usr/local/share/doc/gperftools" ]];then
    mkdir -p ~/src && cd ~/src
    git clone --recursive https://github.com/gperftools/gperftools.git
    cd gperftools
    ./autogen.sh && ./configure && make && sudo make install
    echo "/usr/local/lib" | sudo tee /etc/ld.so.conf
    sudo ldconfig 
    cd "$SCRIPT_DIR"
fi
#=====================================================
# Install or upgrade RUST
echo
echo '################################################'
echo "---INFO: Install RUST ${RUST_VERSION}"
cd "$HOME"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain ${RUST_VERSION} -y
source $HOME/.cargo/env
cargo install cargo-binutils

######################################################
# Build rust node
if ${RUST_NODE_BUILD};then
    echo
    echo '################################################'
    echo "---INFO: build RUST NODE ..."
    echo -e "${BoldText}${BlueBack}---INFO: RNODE git repo:   ${RNODE_GIT_REPO} ${NormText}"
    echo -e "${BoldText}${BlueBack}---INFO: RNODE git commit: ${RNODE_GIT_COMMIT} ${NormText}"
    
    # eval $(ssh-agent -k; ssh-agent -s)

    [[ -d ${RNODE_SRC_DIR} ]] && rm -rf "${RNODE_SRC_DIR}"
    # git clone --recurse-submodules "${RNODE_GIT_REPO}" $RNODE_SRC_DIR
    git clone "${RNODE_GIT_REPO}" "${RNODE_SRC_DIR}"
    cd "${RNODE_SRC_DIR}" 
    git checkout "${RNODE_GIT_COMMIT}"
    git submodule init && git submodule update --recursive
    git submodule foreach 'git submodule init'
    git submodule foreach 'git submodule update  --recursive'

    cd $RNODE_SRC_DIR

    rm -rf ~/.cargo/git/checkouts/ton-*
    rm -rf ~/.cargo/git/checkouts/ever-*

    cargo update

    # Set Link Time Optimization (LTO) for release build
    sed -i.bak '/\[profile\]/,/^$/d' Cargo.toml
    printf '\n[profile.release]\nopt-level = 3\nlto = "thin"\ncodegen-units = 1\npanic = "abort"\n' >> Cargo.toml

    # node git commit
    GC_EVER_NODE="$(git --git-dir="${RNODE_SRC_DIR}/.git" rev-parse HEAD 2>/dev/null)"
    export GC_EVER_NODE
    # block version
    NODE_BLK_VER=$(cat ${RNODE_SRC_DIR}/src/validating_utils.rs |grep -A1 'supported_version'|tail -1|tr -d ' ')
    export NODE_BLK_VER

    echo -e "${BoldText}${BlueBack}---INFO: RNODE build flags: ${RNODE_FEATURES} commit: ${GC_EVER_NODE} Block version: ${NODE_BLK_VER}${NormText}"
    RUSTFLAGS="-C target-cpu=native" cargo build --release --features "${RNODE_FEATURES}"

    find ${RNODE_SRC_DIR}/target/release/ -maxdepth 1 -type f ${FEXEC_FLG} -exec cp -f {} ${NODE_BIN_DIR}/ \;

    if $DAPP_NODE_BUILD;then
        mv -f ${NODE_BIN_DIR}/ever-node ${NODE_BIN_DIR}/ever-node_kafka
        cp -f ${NODE_BIN_DIR}/ever-node_kafka ${NODE_BIN_DIR}/ever-node_kafka-${GC_EVER_NODE}_${BackUP_Time}|cat
        ls -1t ${NODE_BIN_DIR}/ever-node_kafka-* | tail -n +5 | xargs rm -f
    else
        mv -f ${NODE_BIN_DIR}/ever-node ${NODE_BIN_DIR}/rnode
        cp -f ${NODE_BIN_DIR}/rnode ${NODE_BIN_DIR}/rnode-${GC_EVER_NODE}_${BackUP_Time}|cat
        ls -1t ${NODE_BIN_DIR}/rnode-* | tail -n +5 | xargs rm -f
    fi

    echo "---INFO: build RUST NODE ... DONE."
fi
if [[ "$1" == "nodeonly" ]] || [[ "$2" == "nodeonly" ]];then
    rm -f wget-log*
    echo 
    echo '################################################'
    BUILD_END_TIME=$(date +%s)
    Build_mins=$(( (BUILD_END_TIME - BUILD_STRT_TIME)/60 ))
    Build_secs=$(( (BUILD_END_TIME - BUILD_STRT_TIME)%60 ))
    echo
    echo "+++INFO: $(basename "$0") on $HOSTNAME FINISHED $(date +%s) / $(date)"
    echo "All builds took $Build_mins min $Build_secs secs"
    echo "================================================================================================"
    exit 0
fi
#=====================================================
# Build ever-cli
echo
echo '################################################'
echo "---INFO: build ever-cli ... "
echo -e "${BoldText}${BlueBack}---INFO: CLI git repo:   ${TONOS_CLI_GIT_REPO} ${NormText}"
echo -e "${BoldText}${BlueBack}---INFO: CLI git commit: ${TONOS_CLI_GIT_COMMIT} ${NormText}"

[[ -d ${TONOS_CLI_SRC_DIR} ]] && rm -rf "${TONOS_CLI_SRC_DIR}"
git clone --recurse-submodules "${TONOS_CLI_GIT_REPO}" "${TONOS_CLI_SRC_DIR}"
cd "${TONOS_CLI_SRC_DIR}"
git checkout "${TONOS_CLI_GIT_COMMIT}"
cargo update
RUSTFLAGS="-C target-cpu=native" cargo build --release
cp "${TONOS_CLI_SRC_DIR}/target/release/ever-cli" "$NODE_BIN_DIR/"
echo "---INFO: buil ever-cli ... DONE"

#=====================================================
# download contracts
echo
echo '################################################'
echo "---INFO: download contracts ... "
rm -rf "${ContractsDIR}"
rm -rf "${NODE_TOP_DIR}/Surf-contracts"
git clone ${CONTRACTS_GIT_REPO} "${ContractsDIR}"
cd "${ContractsDIR}"
git checkout $CONTRACTS_GIT_COMMIT 
cd "${NODE_TOP_DIR}"
git clone --single-branch --branch ${Surf_GIT_Commit} ${CONTRACTS_GIT_REPO} "${ContractsDIR}/Surf-contracts"


rm -f wget-log*
echo 
echo '################################################'
BUILD_END_TIME=$(date +%s)
Build_mins=$(( (BUILD_END_TIME - BUILD_STRT_TIME)/60 ))
Build_secs=$(( (BUILD_END_TIME - BUILD_STRT_TIME)%60 ))
echo
echo "+++INFO: $(basename "$0") on $HOSTNAME FINISHED $(date +%s) / $(date)"
echo "All builds took $Build_mins min $Build_secs secs"
echo "================================================================================================"

exit 0
