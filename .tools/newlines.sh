#!/bin/bash

source ./.tools/init.sh

aptget_update
aptget_install dos2unix git-core

export LOG1="newlines.log"

rm ${LOG1}

find -H . -type f -name "*.xml" -exec dos2unix {} \; >${LOG1}

export RES=$(git diff --name-only)
if [[ -n "${RES}" ]]; then
    echo "Wrong new lines detected in xml files:"
    git diff --name-only
    exit 1
fi

find -H . -type f -name "*.tmx" -exec dos2unix {} \; >>${LOG1}

export RES=$(git diff --name-only)
if [[ -n "${RES}" ]]; then
    echo "Wrong new lines detected in tmx files:"
    git diff --name-only
    exit 1
fi
