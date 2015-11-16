//
//  MYBlockUtils.m
//  MYUtilities
//
//  Created by Jens Alfke on 1/28/12.
//  Copyright (c) 2012 Jens Alfke. All rights reserved.
//

#import "MYBlockUtils.h"
#import "Test.h"


@interface NSObject (MYBlockUtils)
- (void) my_run_as_block;
@end


/* This is sort of a kludge. This method only needs to be defined for blocks, but their class (NSBlock) isn't public, and the only public base class is NSObject. */
@implementation NSObject (MYBlockUtils)

- (void) my_run_as_block {
    ((void (^)())self)();
}

@end


void MYAfterDelay( NSTimeInterval delay, void (^block)() ) {
#ifndef GNUSTEP
    NSOperationQueue* queue = [NSOperationQueue currentQueue];
    if (queue && ![NSThread isMainThread]) {
        // Can't just call the block directly, because then it won't be running under the control
        // of the operation queue when it's called. So instead, create another block that tells
        // the queue to run the block, then run that...
        block = ^{
            [queue addOperationWithBlock: block];
        };
        if (delay > 0) {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_current_queue(), block);
        } else {
            dispatch_async(dispatch_get_current_queue(), block);
        }
    } else
#endif
    {
        block = [[block copy] autorelease];
        [block performSelector: @selector(my_run_as_block)
                    withObject: nil
                    afterDelay: delay];
    }
}

id MYAfterDelayInModes( NSTimeInterval delay, NSArray* modes, void (^block)() ) {
    block = [[block copy] autorelease];
    [block performSelector: @selector(my_run_as_block)
                withObject: nil
                afterDelay: delay
                   inModes: modes];
    return block;
}

void MYCancelAfterDelay( id block ) {
    [NSObject cancelPreviousPerformRequestsWithTarget: block
                                             selector: @selector(my_run_as_block)
                                               object:nil];
}


void MYOnThread( NSThread* thread, void (^block)()) {
    block = [block copy];
    [block performSelector: @selector(my_run_as_block)
                  onThread: thread
                withObject: block
             waitUntilDone: NO];
    [block release];
}


TestCase(MYAfterDelay) {
    __block BOOL fired = NO;
    MYAfterDelayInModes(0.5, $array(NSRunLoopCommonModes), ^{fired = YES; NSLog(@"Fired!");});
    CAssert(!fired);
    
    while (!fired) {
        if (![[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                      beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]])
            break;
    }
    CAssert(fired);
}
