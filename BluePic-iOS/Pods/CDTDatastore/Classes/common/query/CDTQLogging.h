//
//  CDTQueryLogging.h
//
//  Created by Rhys Short on 07/10/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#ifndef Pods_CDTQueryLogging_h
#define Pods_CDTQueryLogging_h

#import <CocoaLumberjack/CocoaLumberjack.h>

#define CDTQ_LOGGING_CONTEXT 17  // one level higher than CDT logger myabe should be 20?
static DDLogLevel CDTQLogLevel = DDLogLevelWarning;

#define LogError(frmt, ...)                                                                     \
    LOG_MAYBE(NO, CDTQLogLevel, DDLogFlagError, CDTQ_LOGGING_CONTEXT, nil, __PRETTY_FUNCTION__, \
              frmt, ##__VA_ARGS__)
#define LogWarn(frmt, ...)                                                                         \
    LOG_MAYBE(YES, CDTQLogLevel, DDLogFlagWarning, CDTQ_LOGGING_CONTEXT, nil, __PRETTY_FUNCTION__, \
              frmt, ##__VA_ARGS__)
#define LogInfo(frmt, ...)                                                                      \
    LOG_MAYBE(YES, CDTQLogLevel, DDLogFlagInfo, CDTQ_LOGGING_CONTEXT, nil, __PRETTY_FUNCTION__, \
              frmt, ##__VA_ARGS__)
#define LogDebug(frmt, ...)                                                                      \
    LOG_MAYBE(YES, CDTQLogLevel, DDLogFlagDebug, CDTQ_LOGGING_CONTEXT, nil, __PRETTY_FUNCTION__, \
              frmt, ##__VA_ARGS__)
#define LogVerbose(frmt, ...)                                                                      \
    LOG_MAYBE(YES, CDTQLogLevel, DDLogFlagVerbose, CDTQ_LOGGING_CONTEXT, nil, __PRETTY_FUNCTION__, \
              frmt, ##__VA_ARGS__)

#define CDTQChangeLogLevel(level) CDTQLogLevel = level

#endif
