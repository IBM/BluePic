//
//  MYBlockUtils.h
//  MYUtilities
//
//  Created by Jens Alfke on 1/28/12.
//  Copyright (c) 2012 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>


/** Block-based delayed perform. Even works on NSOperationQueues that don't have runloops. */
void MYAfterDelay( NSTimeInterval delay, void (^block)() );

/** Block-based equivalent to -performSelector:withObject:afterDelay:inModes:. */
id MYAfterDelayInModes( NSTimeInterval delay, NSArray* modes, void (^block)() );

/** Cancels a prior call to MYAfterDelayInModes, before the delayed block runs.
    @param block  The return value of the MYAfterDelayInModes call that you want to cancel. */
void MYCancelAfterDelay( id block );

/** Runs the block on the given thread's runloop. */
void MYOnThread( NSThread* thread, void (^block)());
