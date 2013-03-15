//
//  Logger.m
//  Snap
//
//  Created by Abdullah Bakhach on 10/2/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Logger.h"

@implementation Logger


+(void)Log:(NSString *)content
{
    if (FILE_LOG_MODE)
        [Logger logToFile:content];
    else
        [Logger logToConsole:content];        
}

+(void)logToFile:(NSString *)content
{        
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                         NSUserDomainMask, YES); 
    NSString* docDir = [paths objectAtIndex:0];
    NSString * logFile = [docDir stringByAppendingString:@"/log.txt"];                    
    
    content = [content stringByAppendingString:@"\n"];
    NSData *dataToWrite = [content dataUsingEncoding: NSUTF8StringEncoding];
    NSFileHandle* outputFile = [NSFileHandle fileHandleForWritingAtPath:logFile];
    [outputFile seekToEndOfFile];
    [outputFile writeData:dataToWrite];    
    [outputFile closeFile];
    
    NSLog(content);           
}

+(void)logToConsole:(NSString *)content
{
    NSLog(content);
}

@end
