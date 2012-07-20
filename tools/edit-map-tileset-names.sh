#!/bin/bash
for MAP in maps/*.tmx
do
    grep '<tileset\|<image' "$MAP" |
        while read TILESET && read IMAGE
        do
            LINE=$TILESET
            TILESET=${TILESET#*name=\"}
            TILESET=${TILESET%%\"*}
            IMAGE=${IMAGE#*source=\"}
            IMAGE=${IMAGE%%.png\"*}
            IMAGE=${IMAGE##*/}
            sed "/$LINE/s/$TILESET/$IMAGE/" -i "$MAP"
        done
done
