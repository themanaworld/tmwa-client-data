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


function gitclone {
    echo git clone "$1/$2" "$3"
    retry_with_increasing_wait git clone "$1/$2" "$3"
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
    retry_with_increasing_wait apt-get -y -qq update
    check_error $?
}

function aptget_install {
    retry_with_increasing_wait apt-get -y -qq install $*
    check_error $?
}

function clientdata_init {
    mkdir shared
    if [[ "${PWD##*/}" != clientdata && ! -L ../clientdata ]]; then
        ln -s "$PWD" ../clientdata
        check_error $?
    fi
    cd ..
}
