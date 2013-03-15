//
//  NSData+SnapAdditions.m
//  Snap
//
//  Created by Ray Wenderlich on 5/25/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "NSData+SnapAdditions.h"

@implementation NSData (SnapAdditions)

-(double)rw_double64;
{
    CFSwappedFloat64 *doubleBytes = (CFSwappedFloat64 *)[self bytes];
    return CFConvertDoubleSwappedToHost(*doubleBytes);
}
- (int)rw_int32AtOffset:(size_t)offset
{
    const int *intBytes = (const int *)[self bytes];
    return ntohl(intBytes[offset / 4]);
}

- (short)rw_int16AtOffset:(size_t)offset
{
	const short *shortBytes = (const short *)[self bytes];    
	return ntohs(shortBytes[offset / 2]);
}

- (char)rw_int8AtOffset:(size_t)offset
{
	const char *charBytes = (const char *)[self bytes];
	return charBytes[offset];
}

- (NSString *)rw_stringAtOffset:(size_t)offset bytesRead:(size_t *)amount
{
	const char *charBytes = (const char *)[self bytes];
	NSString *string = [NSString stringWithUTF8String:charBytes + offset];
	*amount = strlen(charBytes + offset) + 1;
	return string;
}

@end



@implementation NSMutableData (SnapAdditions)

- (void) rw_appendDouble64:(double)value
{
   CFSwappedFloat64 swappedValue = CFConvertDoubleHostToSwapped(value);
    [self appendBytes:&swappedValue length:8];
}


- (void)rw_appendInt32:(int)value
{
	value = htonl(value);
	[self appendBytes:&value length:4];
}

- (void)rw_appendInt16:(short)value
{
	value = htons(value);
	[self appendBytes:&value length:2];
}

- (void)rw_appendInt8:(char)value
{
	[self appendBytes:&value length:1];
}

- (void)rw_appendString:(NSString *)string
{
	const char *cString = [string UTF8String];
	[self appendBytes:cString length:strlen(cString) + 1];
}

@end
