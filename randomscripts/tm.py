#!/usr/bin/env python3.0

import os
import os.path
import sys
import shutil

baseDir = "/Volumes/Drobo/Backups.backupdb/srv/"

def main(argv=None):
    if argv is None:
        argv = sys.argv
    
    #opts, args = getopt.getopt(sys.argv[1:], "d:")

    file = sys.argv[1]
    
    fullPath = os.path.abspath(file)
    
    if fullPath.startswith("/Volumes"):
       fullPath = fullPath[8:]
    
    fileLocations = []
    
    
    print("Please be patient danielson.  Looking for copies of:\n" + fullPath)
    print()
    print(" *  <-- imagine that's spinning or something, like a good mac os app would do")
    print()
    
    for base in os.listdir(baseDir):
        
        if base.endswith(".inProgress"):
            continue
        
        tmPath = baseDir + base + fullPath
        
        if os.path.exists(tmPath):
            fileLocations.append(tmPath)
    
    fileLocations.sort()
        
    command = "l"
    
    while True:
        
        if command.startswith("k"):
            print("Goodbye!")
            sys.exit(0)
        
        elif command == "l":
            
            idx = 0
            for l in fileLocations:
                idx = idx + 1
                
                l = l[len(baseDir):]
                
                print("%d  %s" % (idx, l))
        
        elif command.startswith("q"):
            
            (junk, index) = command.split()
            v = int(index) - 1
            
            os.popen("/usr/bin/qlmanage -p '" + fileLocations[v] + "' 2>&1").read()
            
        
        elif command.startswith("r"):
            
            (junk, index) = command.split()
            v = int(index) - 1
            
            print("Restore " + fileLocations[v] + "? (y/n)")
            
            if sys.stdin.readline().strip() == "y":
                print("Copying...")
                shutil.copy(fileLocations[v], sys.argv[1])
                print("All done.")
            else:
                print("Ok, I thought you were just kidding.  I had to make sure though.")
            
            
        else:
            print("Unknown command '%s'" % (command))
        
        
        print("q [index] to quicklook, k to quit, r [index] to restore")
        
        
        command = sys.stdin.readline().strip()
        
        if len(command) == 0:
            command = "k"
        
    
    

if __name__ == '__main__':
    main()
    