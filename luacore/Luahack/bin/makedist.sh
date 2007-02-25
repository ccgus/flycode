#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`
BUILD_DIR="/tmp/fo"
cd $SRC_HOME

xcodebuild -buildstyle Deployment -project Luahack.xcodeproj build OBJROOT=$BUILD_DIR SYMROOT=$BUILD_DIR

mkdir -p dist/Luahack

cp -r /tmp/fo/Deployment/Luahack.bundle dist/Luahack/.
cp resources/Info dist/Luahack/.

cd dist
