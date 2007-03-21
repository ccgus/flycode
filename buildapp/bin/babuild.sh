#!/bin/bash

revision=""
upload=1
twitter=""

while [ "$#" -gt 0 ]
do
    case "$1" in
        --revision|-r)
                revision="-r $2"
                upload=0
                break
                ;;
        --noupload|-n)
                upload=0
                break
                ;;
        --twitter|-t)
                twitter="$2"
                break
                ;;
        *)
                echo "$CMDNAME: invalid option: $1" 1>&2
                exit 1
                ;;
    esac
    shift
done

# this is where our final build ends up
if [ ! -d  ~/svnbuilds ]; then
    mkdir ~/svnbuilds
fi

if [ -f /tmp/BuildAppPreview.dmg ]; then
    rm /tmp/BuildAppPreview.dmg
fi

cd /tmp

echo "doing checkout ($revision)"

if [ -f /tmp/buildapp ]; then
    rm /tmp/buildapp
fi
svn co $revision http://flycode.googlecode.com/svn/trunk/buildapp buildapp


cd /tmp/buildapp

buildDate=`/bin/date +"%Y.%m.%d.%H"`
v=`svnversion -n /tmp/buildapp`

echo setting build date
sed -e "s/BUILDID/$v/g"  res/Info.plist > res/Info.plist.tmp

mv res/Info.plist.tmp res/Info.plist

find . | grep \.svn$ | xargs rm -rf


# got tests?
#echo running tests
#xcodebuild -target TestTarget  -configuration Release OBJROOT=/tmp/buildapp/build SYMROOT=/tmp/buildapp/build OTHER_CFLAGS="" 

#if [ $? != 0 ]; then
#    echo "Bad test results"
#    exit
#fi


echo building project
xcodebuild -target BuildApp  -configuration Release OBJROOT=/tmp/buildapp/build SYMROOT=/tmp/buildapp/build OTHER_CFLAGS="" 

if [ $? != 0 ]; then
    echo "Bad build for BuildApp"
    say "bad build!"
else
    
    #ok, let's index the documentation if we've got it.
    #/Developer/Applications/Utilities/Help\ Indexer.app/Contents/MacOS/Help\ Indexer "/tmp/buildapp/build/Release/BuildApp.app/Contents/Resources/English.lproj/BuildAppHelp"
    
    cd /tmp/buildapp/
    
    mv /tmp/buildapp/build/Release/BuildApp.app ~/svnbuilds/.
    
    # make the disks.
    /tmp/buildapp/bin/makedisk.sh
    
    # if you see stuff print out- gotta do something about that :)
    cd ~/svnbuilds/
    find . | grep h$
    find . | grep svn
    
    rm -rf ~/svnbuilds/BuildApp.app
    
    cd ~/svnbuilds/
    
    cp BuildAppPreview.dmg $v-BuildAppPreview.dmg
    
    if [ $upload == 1 ]; then
        
        echo uploading to server...
        # upload your disk here.
        
        if [ "$twitter" != "" ]; then
            echo "Calling twitter: $twitter"
            curl -u someone@somewhere.com:password -d status="BuildApp v$v is up. $twitter" http://twitter.com/statuses/update.xml
        fi
        
    fi
    
    open ~/svnbuilds
    
    say "done building"
    
    
fi

rm -rf /tmp/buildapp