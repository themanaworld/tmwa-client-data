#!/bin/bash

source ./.tools/init.sh

clientdata_init

aptget_update
aptget_install git-core libxml2-utils python python-pil python-pyvorbis

rm -rf tools
gitclone https://git.themanaworld.org/evolved tools.git tools

cd tools/CI/testxml

./xsdcheck.sh
check_error $?
export RES=$(cat errors.txt)
if [[ -n "${RES}" ]]; then
    echo "xml check failed" >../../../clientdata/shared/error.log
    cat errors.txt >>../../../clientdata/shared/error.log
    cat ../../../clientdata/shared/error.log
    exit 1
fi

echo >../../../clientdata/shared/error.log
./testxml.py stfu >../../../clientdata/shared/error.log
res="$?"
cat ../../../clientdata/shared/error.log
if [ "$res" != 0 ]; then
    echo "test xml error"
    exit 1
fi

echo >../../../clientdata/shared/error.log
