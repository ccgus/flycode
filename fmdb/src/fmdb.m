#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    // delete the old db.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeFileAtPath:@"/tmp/tmp.db" handler:nil];
    
    FMDatabase* db = [FMDatabase databaseWithPath:@"/tmp/tmp.db"];
    if (![db open]) {
        NSLog(@"Could not open db.");
        return 0;
    }
    
    // create a bad statement, just to test the error code.
    [db executeUpdate:@"blah blah blah"];
    if ([db hadError]) {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
    
    // but of course, I don't bother checking the error codes below.
    // Bad programmer, no cookie.
    
    [db executeUpdate:@"create table test (a text, b text, c integer, d double, e double)"];
    
    
    [db beginTransaction];
    int i = 0;
    while (i++ < 20) {
        [db executeUpdate:@"insert into test (a, b, c, d, e) values (?, ?, ?, ?, ?)" ,
            @"hi'", // look!  I put in a ', and I'm not escaping it!
            [NSString stringWithFormat:@"number %d", i],
            [NSNumber numberWithInt:i],
            [NSDate date],
            [NSNumber numberWithFloat:2.2f]];
    }
    [db commit];
    
    
    FMResultSet *rs = [db executeQuery:@"select rowid,* from test where a = ?", @"hi'"];
    while ([rs next]) {
        // just print out what we've got in a number of formats.
        NSLog(@"%d %@ %@ %@ %@ %f %f",
              [rs intForColumn:@"c"],
              [rs stringForColumn:@"b"],
              [rs stringForColumn:@"a"],
              [rs stringForColumn:@"rowid"],
              [rs dateForColumn:@"d"],
              [rs doubleForColumn:@"d"],
              [rs doubleForColumn:@"e"]);
    }
    // close the result set.
    // it'll also close when it's dealloc'd, but we're closing the database before
    // the autorelease pool closes, so sqlite will complain about it.
    [rs close];  
    
    // ----------------------------------------------------------------------------------------
    // blob support.
    [db executeUpdate:@"create table blobTable (a text, b blob)"];
    
    // let's read in an image from safari's app bundle.
    NSData *d = [NSData dataWithContentsOfFile:@"/Applications/Safari.app/Contents/Resources/compass.icns"];
    if (d) {
        [db executeUpdate:@"insert into blobTable (a, b) values (?,?)", @"safari's compass", d];
        
        rs = [db executeQuery:@"select b from blobTable where a = ?", @"safari's compass"];
        if ([rs next]) {
            d = [rs dataForColumn:@"b"];
            [d writeToFile:@"/tmp/compass.icns" atomically:NO];
            
            // let's look at our fancy image that we just wrote out..
            system("/usr/bin/open /tmp/compass.icns");
        }
        else {
            NSLog(@"Could not select image.");
        }
        
        [rs close];
        
    }
    else {
        NSLog(@"Can't find compass image..");
    }
    
    
    // test out the convenience methods in +Additions
    [db executeUpdate:@"create table t1 (a integer)"];
    [db executeUpdate:@"insert into t1 values (5)"];
    int a = [db intForQuery:@"select a from t1 where a = ?", [NSNumber numberWithInt:5]];
    if (a != 5) {
        NSLog(@"intForQuery didn't work (a != 5)");
    }
    
    
    
    
    [db close];
    
    [pool release];
    return 0;
}
