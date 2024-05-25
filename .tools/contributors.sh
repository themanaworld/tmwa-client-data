#!/bin/bash

source ./.tools/init.sh

clientdata_init

aptget_update
aptget_install git-core make xsltproc

rm -rf tools
gitclone https://git.themanaworld.org/evolved tools.git tools

cd tools/contrib_xsl

make about-server
check_error $?

cd ../../clientdata

export RES=$(git diff)
if [[ -n "${RES}" ]]; then
    echo "Contributors list not updated"
    git diff
    exit 1
fi
