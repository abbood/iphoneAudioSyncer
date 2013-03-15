//
//  Logger.h
//  Snap
//
//  Created by Abdullah Bakhach on 10/2/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <Foundation/Foundation.h>


#define FILE_LOG_MODE true

@interface Logger : NSObject

+(void)Log:(NSString *)content;

@end
