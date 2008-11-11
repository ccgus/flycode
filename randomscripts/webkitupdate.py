#!/usr/bin/python

import os
import os.path
import sys

# you're going to want to change this location.
appFolder = "/Volumes/srv/Users/gus/Applications"

if not os.path.exists(appFolder):
    print("The folder " + appFolder + " does not exist.")
    sys.exit(1)

s = os.popen("curl http://nightly.webkit.org/builds/trunk/mac/rss").read()

sloc = s.find('<guid>')
eloc = s.find('</guid>')

#url = "http://builds.nightly.webkit.org/" + s[sloc+10:eloc + 4]

url = s[sloc+6: eloc]

print url

os.chdir("/tmp")

os.popen("curl -O " + url)
os.popen("/usr/bin/hdiutil mount WebKit-SVN*.dmg")
os.popen("killall Safari")

os.popen("rm -r " + appFolder + "/WebKit.app")

os.popen("cp -rp /Volumes/WebKit/WebKit.app " + appFolder + "/")

os.popen("hdiutil detach /Volumes/WebKit")

os.popen("rm /tmp/WebKit-SVN*.dmg")

os.popen("open -a WebKit")

