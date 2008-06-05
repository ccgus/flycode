#!/usr/bin/python

import os
import os.path
import sys

# you're going to want to change this location.
appFolder = "/Volumes/srv/Users/gus/Applications"

if not os.path.exists(appFolder):
    print("The folder " + appFolder + " does not exist.")
    sys.exit(1)

s = os.popen("curl http://nightly.webkit.org/").read()

sloc = s.find('<a href="/files/trunk/mac/WebKit-SVN-')
eloc = s.find('.dmg"')

url = "http://nightly.webkit.org/" + s[sloc+10:eloc + 4]

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

