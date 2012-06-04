#!/bin/bash

cd ..

for f in $(find -name "*.xml")
do
    if [ ${f} != "./items.xml" ]; then
        xsltproc tools/indent.xsl ${f} > ${f}__
        mv ${f}__ ${f}
    fi
done
xmlindent items.xml > items.xml_
sed 's/[[:space:]]*$//' items.xml_ > items.xml
