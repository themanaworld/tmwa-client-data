#!/bin/bash

source ./.tools/init.sh

clientdata_init

aptget_update
# Evidently libcurl3-gnutls ships libcurl4-gnutls.so.4
aptget_install \
    libcurl3-gnutls \
    libsdl-gfx1.2 libsdl-image1.2 libsdl-mixer1.2 libsdl-net1.2 libsdl-ttf2.0 \
    wget unzip

pwd
ls

./clientdata/.tools/downloadlib.sh manaplus master || exit 1

export HOME=`pwd`/clientdata/shared

cd manaplus_master || exit 1
export SDL_VIDEODRIVER=dummy
./bin/manaplus --validate -u -d ../clientdata || exit 1

logfile="${HOME}/.local/share/mana/manaverse.log"
if [[ ! -f "$logfile" ]]; then
    printf "Error: logfile %s not found\n" "$logfile"
    exit 1
fi

grep -A 10 "Assert:" "$logfile"

if [ "$?" == 0 ]; then
    echo "Asserts found"
    exit 1
fi

cd ..
