#!/bin/bash

source ./.tools/init.sh

clientdata_init

aptget_update
aptget_install gcc g++ \
    make autoconf automake autopoint gettext \
    libxml2-dev libcurl4-gnutls-dev libpng-dev \
    libsdl-gfx1.2-dev libsdl-image1.2-dev libsdl-mixer1.2-dev libsdl-net1.2-dev libsdl-ttf2.0-dev \
    wget unzip

pwd
ls

./clientdata/.tools/downloadlib.sh manaplus master || exit 1

export HOME=`pwd`/clientdata/shared

cd manaplus_master || exit 1
export SDL_VIDEODRIVER=dummy
./bin/manaplus --validate -u -d ../clientdata || exit 1

ls "${HOME}/.local/share/mana/manaplus.log" || exit 1
grep -A 10 "Assert:" "${HOME}/.local/share/mana/manaplus.log"

if [ "$?" == 0 ]; then
    echo "Asserts found"
    exit 1
fi

cd ..
