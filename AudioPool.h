//
//  audioPool.h
//  Snap
//
//  Created by Abdullah Bakhach on 9/7/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioItem.h"

#define POOL_CAPACITY  8388608   // limit pool capacity to 8 megabytes

@interface AudioPool : NSObject
{
    NSMutableDictionary *pool;
}


@property (nonatomic, strong) NSMutableDictionary *pool;

-(id)initPool;
-(AudioItem *)createItemAndAddToPool:(NSString *)itemID;
-(void)purgeReadData:(AudioItem *)item
              length:(UInt32)length;
@end
