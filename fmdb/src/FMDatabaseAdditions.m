//
//  FMDatabaseAdditions.m
//  fmkit
//
//  Created by August Mueller on 10/30/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

@implementation FMDatabase (FMDatabaseAdditions)

#define RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(type, sel)             \
va_list args;                                                        \
va_start(args, query);                                               \
FMResultSet *resultSet = [self executeQuery:query arguments:args];   \
va_end(args);                                                        \
if (![resultSet next]) { return (type)0; }                           \
type ret = [resultSet sel:0];                                        \
[resultSet close];                                                   \
[resultSet setParentDB:nil];                                         \
return ret;


- (NSString*)stringForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(NSString *, stringForColumnIndex);
}

- (int)intForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(int, intForColumnIndex);
}

- (long)longForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(long, longForColumnIndex);
}

- (BOOL)boolForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(BOOL, boolForColumnIndex);
}

- (double)doubleForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(double, doubleForColumnIndex);
}

- (NSData*)dataForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(NSData *, dataForColumnIndex);
}


//From Phong Long:
//sometimes you want to be able generate queries programatically
//with an arbitrary number of arguments, as well as be able to bind
//them properly. this method allows you to pass in a query string with any
//number of ?, then you pass in an appropriate number of objects in an NSArray
//to executeQuery:arguments:

//this technique is being implemented as described by Matt Gallagher at
//http://cocoawithlove.com/2009/05/variable-argument-lists-in-cocoa.html

- (id)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {

	id returnObject;
	
	//also need make sure that everything in arguments is an Obj-C object
	//or else argList will be the wrong size
	NSUInteger argumentsCount = [arguments count];
	char *argList = (char *)malloc(sizeof(id *) * argumentsCount);
	[arguments getObjects:(id *)argList];
	
	returnObject = [self executeQuery:sql arguments:argList];
	
	free(argList);
	
	return returnObject;
}

- (BOOL) executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments {
    
    BOOL returnBool;
	
	//also need make sure that everything in arguments is an Obj-C object
	//or else argList will be the wrong size
	NSUInteger argumentsCount = [arguments count];
	char *argList = (char *)malloc(sizeof(id *) * argumentsCount);
	[arguments getObjects:(id *)argList];
	
	returnBool = [self executeUpdate:sql arguments:argList];
	
	free(argList);
	
	return returnBool;
    
}




@end
