#!/bin/bash

function check_error {
    if [ "$1" != 0 ]; then
        echo "Error $1"
        exit $1
    fi
}

function gitclone1 {
    echo git clone $2 $3
    git clone $2 $3
    if [ "$?" != 0 ]; then
        echo git clone $1 $3
        git clone $1 $3
        return $?
    fi
    return $?
}

function gitclone {
    export name1=$1/$2
    export name2=${CI_BUILD_REPO##*@}
    export name2=https://${name2%/*}/$2

    gitclone1 "$name1" "$name2" $3
    if [ "$?" != 0 ]; then
        sleep 1s
        gitclone1 "$name1" "$name2" $3
        if [ "$?" != 0 ]; then
            sleep 3s
            gitclone1 "$name1" "$name2" $3
            if [ "$?" != 0 ]; then
                sleep 5s
                gitclone1 "$name1" "$name2" $3
            fi
        fi
    fi
    check_error $?
}

function update_repos {
    if [ "$CI_SERVER" == "" ];
    then
        return
    fi

    export DATA=$(cat /etc/resolv.conf|grep "nameserver 1.10.100.101")
    if [ "$DATA" != "" ];
    then
        echo "Detected local runner"
        sed -i 's!http://httpredir.debian.org/debian!http://1.10.100.103/debian!' /etc/apt/sources.list
    else
        echo "Detected non local runner"
    fi
}

function aptget_update {
    update_repos
    apt-get update
    if [ "$?" != 0 ]; then
        sleep 1s
        apt-get update
        if [ "$?" != 0 ]; then
            sleep 1s
            apt-get update
        fi
    fi
    check_error $?
}

function aptget_install {
    apt-get -y -qq install $*
    if [ "$?" != 0 ]; then
        sleep 1s
        apt-get -y -qq install $*
        if [ "$?" != 0 ]; then
            sleep 2s
            apt-get -y -qq install $*
        fi
    fi
    check_error $?
}

function clientdata_init {
    mkdir shared
    cd ..
    ln -s clientdata client-data
    check_error $?
}
