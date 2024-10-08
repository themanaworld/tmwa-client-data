#!/bin/bash

source ./.tools/init.sh

clientdata_init

aptget_update
aptget_install git-core grep

rm -rf tools
gitclone https://git.themanaworld.org/evolved tools.git tools

cd tools/CI/licensecheck

./clientdata.sh >license.log
check_error $?

export RES=$(cat license.log)
if [[ -n "${RES}" ]]; then
    echo "Detected missing licenses."
    cat license.log
    echo "Estimated total missing licenses:"
    wc -l license.log
    exit 1
fi
