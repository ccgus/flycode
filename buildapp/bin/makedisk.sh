#!/bin/bash

BASE_DIR=`cd ${0%/*}/..; pwd`

cd $BASE_DIR

# eject any disks named BuildApp
if [ -d /Volumes/BuildApp ]; then
    /usr/bin/hdiutil unmount /Volumes/BuildApp
fi

# remove any versions of this that might still be around for some reason.
if [ -f /tmp/BuildApp.dmg ]; then
    rm /tmp/BuildApp.dmg
fi

# expand our template to /tmp
/usr/bin/gunzip --to-stdout res/BuildAppDiskTemplate.sparseimage.gz > /tmp/BuildAppWrite.sparseimage

# mount the disk.
/usr/bin/hdiutil attach /tmp/BuildAppWrite.sparseimage

sleep 2

# copy our app into the disk image
cp -R ~/svnbuilds/BuildApp.app/* /Volumes/BuildApp/BuildApp.app/.

/usr/bin/hdiutil eject /Volumes/BuildApp

sleep 2

# convert to a "UDIF zlib-compressed image"
/usr/bin/hdiutil convert /tmp/BuildAppWrite.sparseimage -format UDZO -o /tmp/BuildApp

# cleanup
rm /tmp/BuildAppWrite.sparseimage

# move it to our official builds dir
mv /tmp/BuildApp.dmg ~/svnbuilds/.

#open /tmp/BuildApp.dmg