#!/bin/bash

spm_branch="$1"
client_branch="$2"
logfile="$3"

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

./clientdata/.tools/downloadlib.sh "$spm_branch" manaplus "$client_branch" || exit 1

export HOME="$PWD/clientdata/shared"

pushd "manaplus_$client_branch" || exit 1
export SDL_VIDEODRIVER=dummy
./bin/manaplus --version || exit 1
./bin/manaplus --validate -u -d ../clientdata || exit 1

log_path="$HOME/.local/share/mana/$logfile"
if [[ ! -f "$log_path" ]]; then
    printf "Error: logfile %s not found\n" "$log_path"
    exit 1
fi

grep -A 10 "Assert:" "$log_path"

if [ "$?" == 0 ]; then
    echo "Asserts found"
    exit 1
fi

popd
