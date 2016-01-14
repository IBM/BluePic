//
//  MYStreamUtils.m
//  MYUtilities
//
//  Created by Jens Alfke on 7/25/12.
//
//

#import "MYStreamUtils.h"

#define kReadBufferSize 32768


@implementation NSInputStream (MYUtils)


- (BOOL) my_readBytes: (void(^)(const void* bytes, NSUInteger length))block {
    uint8_t* buffer;
    NSUInteger bufferLen;
    if ([self getBuffer: &buffer length: &bufferLen]) {
        block(buffer, bufferLen);
        return YES;
    } else {
        buffer = malloc(kReadBufferSize);
        if (!buffer)
            return NO;
        NSInteger bytesRead = [self read: buffer maxLength: kReadBufferSize];
        BOOL success = bytesRead >= 0;
        if (success)
            block(buffer, bytesRead);
        free(buffer);
        return success;
    }
}


- (BOOL) my_readData: (void(^)(NSData* data))block {
    return [self my_readBytes: ^(const void *bytes, NSUInteger length) {
        NSData* data = [[NSData alloc] initWithBytesNoCopy: (void*)bytes length: length
                                              freeWhenDone: NO];
        block(data);
        [data release];
    }];
}


@end
