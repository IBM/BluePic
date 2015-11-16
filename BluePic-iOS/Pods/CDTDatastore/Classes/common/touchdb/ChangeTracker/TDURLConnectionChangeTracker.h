//
//  TDURLConnectionChangeTracker.h
//  
//
//  Created by Adam Cox on 1/5/15.
//
//

#import "TDChangeTracker.h"

@interface TDURLConnectionChangeTracker : TDChangeTracker <NSURLSessionTaskDelegate>

// used only for testing and debugging. counts the total number of retry attempts and
// is not reset to zero with each separate request (unlike TDChangeTracker retryCount).
@property (nonatomic, readonly) NSUInteger totalRetries;

@end
