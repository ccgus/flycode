#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`

cd $SRC_HOME

# remove the old one.
if [ -d ~/Library/InputManagers/GBHack ]; then
    rm -rf ~/Library/InputManagers/GBHack
fi

./bin/makedist.sh

mkdir -p ~/Library/InputManagers

cp -r dist/GBHack ~/Library/InputManagers/
