//
//  audioPool.m
//  Snap
//
//  Created by Abdullah Bakhach on 9/7/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#include <AudioToolBox/AudioToolBox.h>

#import "AudioPool.h"

@implementation AudioPool

@synthesize pool;



-(id)initPool
{
    self = [super init];
    pool = [NSMutableDictionary dictionaryWithCapacity:POOL_CAPACITY];    
    

    
    return self;
}

-(AudioItem *)createItemAndAddToPool:(NSString *)itemID
{
    AudioItem *item = [[AudioItem alloc] initWithID:itemID];
    [pool setObject:item forKey:itemID];
    
    return item;    
}



@end


