#!/bin/bash
for MAP in $(ls maps | grep '\.tmx$')
do
    TILESETS=$(
        grep '<tileset' "maps/$MAP" |
            while read TILESET
            do
                TILESET=${TILESET#*name=\"}
                TILESET=${TILESET%%\"*}
                echo tilesets/${TILESET}.tsx
            done
    )
    rm -f ${TILESETS}
    (cd tilesets; tiled ../maps/$MAP;)
    git add -N tilesets/
    git add --patch
done


