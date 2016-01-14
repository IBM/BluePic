//
//  CDTLogging.h
//  CloudantSync
//
//
//  Created by Rhys Short on 01/10/2014.
//  Copyright (c) 2014 Cloudant. All rights reserved.
//
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import <CocoaLumberjack/CocoaLumberjack.h>

#ifndef _CDTLogging_h
#define _CDTLogging_h

/*

 Macro definitions for custom logger contexts, this allows different parts of CDTDatastore
 to separate its log messages and have different levels.

 Each component should set its log level using a static variable in the name <component>LogLevel
 the macros will then perform correctly at compile time.

 */

#define CDTINDEX_LOG_CONTEXT 10
#define CDTREPLICATION_LOG_CONTEXT 11
#define CDTDATASTORE_LOG_CONTEXT 12
#define CDTDOCUMENT_REVISION_LOG_CONTEXT 13
#define CDTTD_REMOTE_REQUEST_CONTEXT 14
#define CDTTD_JSON_CONTEXT 15
#define CDTTD_VIEW_CONTEXT 16

#define CDTSTART_CONTEXT CDTINDEX_LOG_CONTEXT
#define CDTEND_CONTEXT CDTTD_VIEW_CONTEXT

#ifdef DEBUG

    #ifndef CDTLogAsync

        #define CDTLogAsync NO

    #endif

#else

    #ifndef CDTLogAsync

        #define CDTLogAsync YES

    #endif

#endif

extern DDLogLevel CDTLoggingLevels[];

#define CDTLogError(context, frmt, ...)                                                    \
    LOG_MAYBE(NO, CDTLoggingLevels[context - CDTSTART_CONTEXT], DDLogFlagError, context, nil, \
              __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define CDTLogWarn(context, frmt, ...)                                                        \
    LOG_MAYBE(CDTLogAsync, CDTLoggingLevels[context - CDTSTART_CONTEXT], DDLogFlagWarning, context, nil, \
              __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define CDTLogInfo(context, frmt, ...)                                                     \
    LOG_MAYBE(CDTLogAsync, CDTLoggingLevels[context - CDTSTART_CONTEXT], DDLogFlagInfo, context, nil, \
              __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define CDTLogDebug(context, frmt, ...)                                                     \
    LOG_MAYBE(CDTLogAsync, CDTLoggingLevels[context - CDTSTART_CONTEXT], DDLogFlagDebug, context, nil, \
              __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define CDTLogVerbose(context, frmt, ...)                                                     \
    LOG_MAYBE(CDTLogAsync, CDTLoggingLevels[context - CDTSTART_CONTEXT], DDLogFlagVerbose, context, nil, \
              __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define CDTChangeLogLevel(context, logLevel) CDTLoggingLevels[context - CDTSTART_CONTEXT] = logLevel

#endif
