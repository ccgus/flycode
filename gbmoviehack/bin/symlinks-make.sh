#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`

cd $SRC_HOME

if [ -d ~/Library/InputManagers/GBHack ]; then
    rm -rf ~/Library/InputManagers/GBHack
fi

#ln -s 

mkdir ~/Library/InputManagers/GBHack

cd ~/Library/InputManagers/GBHack

ln -s $SRC_HOME/resources/Info .

if [ -d ~/builds ]; then
    echo ehy!
    ln -s ~/builds/Development/GBHack.bundle .
else
    ln -s $SRC_HOME/build/GBHack.bundle .
fi