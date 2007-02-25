#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`

cd $SRC_HOME

# remove the old one.
if [ -d ~/Library/InputManagers/Luahack ]; then
    rm -rf ~/Library/InputManagers/Luahack
fi

./bin/makedist.sh

mkdir -p ~/Library/InputManagers

cp -r dist/Luahack ~/Library/InputManagers/
