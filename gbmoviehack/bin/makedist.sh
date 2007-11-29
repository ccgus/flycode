#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`
BUILD_DIR="/tmp/fo"
cd $SRC_HOME

xcodebuild -buildstyle Deployment -project gbhack.xcodeproj build OBJROOT=$BUILD_DIR SYMROOT=$BUILD_DIR

mkdir -p dist/GBHack

cp -r /tmp/fo/Deployment/GBHack.bundle dist/GBHack/.
cp resources/Info dist/GBHack/.

cd dist

tar cvfz GBHack.tgz GBHack
scp GBHack.tgz gus@elvis:~/www/x/.