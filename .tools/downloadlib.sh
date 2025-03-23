#!/bin/bash

export zipname="lib.zip"
export branch="$1"
export libname="$2_$3"

rm -rf libdownload
mkdir libdownload
cd libdownload

wget --retry-connrefused --retry-on-host-error --tries=10 --waitretry=5 \
     -O "$zipname" \
     --progress=dot:mega \
     "https://git.themanaworld.org/mana/spm/builds/artifacts/$branch/download?job=$libname"

unzip "${zipname}"
cp -r "bin/${libname}" ..
cd ..

rm -rf /usr/local/spm/bin/${libname}
mkdir -p /usr/local/spm/bin

cp -r libdownload/bin/${libname} /usr/local/spm/bin/
ls /usr/local/spm/bin/${libname}
if [ "$?" != 0 ]; then
    printf "Library %s %s %s unpack failed" "$1" "$2" "$3"
    exit 1
fi
