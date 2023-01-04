#!/bin/bash

source ./.tools/init.sh

clientdata_init

aptget_update
aptget_install git-core zip gcc zlib1g-dev ca-certificates libxml2-utils python
rm -rf tools
gitclone https://git.themanaworld.org/evolved tools.git tools

cd clientdata
rm -rf public
mkdir public

cd ..

# FIXME
#rm -rf music
#gitclone https://git.themanaworld.org/evolved music.git music

cd tools/update

# FIXME
./createnew.sh
check_error $?
#./create_music.sh
#check_error $?

cp -r upload/* ../../clientdata/public
cd ../../clientdata
gitclone https://git.themanaworld.org/mana pagesindexgen.git pagesindexgen
cd pagesindexgen
./pagesindexgen.py ../public
check_error $?
ls ../public
