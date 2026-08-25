#!/bin/bash

source ./.tools/init.sh

clientdata_init

aptget_update
aptget_install ca-certificates git-core imagemagick

rm -rf tools
gitclone https://git.themanaworld.org/tmw tools.git tools

cd tools/imagescheck

./icccheck.sh >icccheck.log
check_error $?

export RES=$(cat icccheck.log)
if [[ -n "${RES}" ]]; then
    echo "Detected icc profiles"
    cat icccheck.log
    exit 1
fi
