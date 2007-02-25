#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`
cd $SRC_HOME

if [ -d ~/Library/InputManagers/Luahack ]; then
    rm -rf ~/Library/InputManagers/Luahack
fi
