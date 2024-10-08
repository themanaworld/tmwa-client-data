#!/bin/bash

function check_error {
    if [ "$1" != 0 ]; then
        echo "Error $1"
        exit $1
    fi
}

retry_with_increasing_wait()
{
    local wait_time=1

    while true; do
        "$@"
        local retval=$?

        if [[ $retval -eq 0  ||  $wait_time -gt 16 ]]; then
            break
        fi

        printf "command %s failed (exit code %d), waiting %d seconds until next try.\n"\
               "$*" "$retval" "$wait_time"

        sleep "$wait_time"
        # 1, 2, 4, 8, 16...
        (( wait_time = 2 * wait_time ))
    done

    return "$retval"
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

    retry_with_increasing_wait gitclone1 "$name1" "$name2" "$3"
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
    retry_with_increasing_wait apt-get update
    check_error $?
}

function aptget_install {
    retry_with_increasing_wait apt-get -y -qq install $*
    check_error $?
}

function clientdata_init {
    mkdir shared
    cd ..
    ln -s clientdata client-data
    check_error $?
}
