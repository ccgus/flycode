#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`

cd /tmp

if [ -d gbhack_src ]; then
    rm -rf gbhack_src
fi


svn export svn+ssh://elvis.mu.org/home/mu.org/home/gus/subversion/stuff/gbhack/trunk gbhack_src

if [ -f gbhack_src.tgz ] ; then
    rm gbhack_src.tgz
fi

tar cvfz gbhack_src.tgz gbhack_src

scp gbhack_src.tgz gus@elvis:~/www/gbhack/.
