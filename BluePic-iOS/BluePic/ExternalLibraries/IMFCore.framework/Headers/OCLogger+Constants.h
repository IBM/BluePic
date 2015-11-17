/*
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corp. 2006, 2013. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */
#import <Foundation/Foundation.h>

extern NSString* const TAG_LABEL_TRACE;
extern NSString* const TAG_LABEL_DEBUG;
extern NSString* const TAG_LABEL_LOG;
extern NSString* const TAG_LABEL_INFO;
extern NSString* const TAG_LABEL_WARN;
extern NSString* const TAG_LABEL_ERROR;
extern NSString* const TAG_LABEL_FATAL;
extern NSString* const TAG_LABEL_ANALYTICS;


extern NSString* const LABEL_NO_PACKAGE;
extern NSString* const INVALID_DATA;

extern NSString* const KEY_MAX_FILE_SIZE;
extern NSString* const KEY_LEVEL;
extern NSString* const KEY_CAPTURE;
extern NSString* const KEY_FILTER;
extern NSString* const KEY_ANALYTICS_CAPTURE;
extern NSString* const KEY_AUTO_SEND;

extern NSString* const KEY_SERVER_LEVEL;
extern NSString* const KEY_SERVER_CAPTURE;
extern NSString* const KEY_SERVER_FILTER;

extern NSString* const BOOL_STR_TRUE;
extern NSString* const BOOL_STR_FALSE;

extern NSString* const FILENAME_WL_LOG;
extern NSString* const FILENAME_WL_LOG_SWAP;
extern NSString* const FILENAME_WL_LOG_SEND;
extern NSString* const FILENAME_ANALYTICS_LOG;
extern NSString* const FILENAME_ANALYTICS_SWAP;
extern NSString* const FILENAME_ANALYTICS_SEND;

extern int const DEFAULT_LOW_BOUND_FILE_SIZE;
extern int const DEFAULT_MAX_FILE_SIZE;
extern int const BUFFER_TIME_IN_SECONDS;

extern int const HTTP_SC_OK;
extern int const HTTP_SC_NO_CONTENT;
extern int const HTTP_SC_BAD_REQUEST;

extern NSString* const DEFAULT_TIME_FORMAT;

extern NSString* const LOG_UPLOADER_PATH;

extern NSString* const CONFIG_URI_PATH;

extern NSString* const TAG_MSG;
extern NSString* const TAG_PKG;
extern NSString* const TAG_TIMESTAMP;
extern NSString* const TAG_LEVEL;
extern NSString* const TAG_META_DATA;

extern NSString* const TAG_CAPTURE;
extern NSString* const TAG_ANALYTICS_CAPTURE;
extern NSString* const TAG_MAX_FILE_SIZE;
extern NSString* const TAG_LOG_LEVEL;
extern NSString* const TAG_UNCAUGHT_EXCEPTION;
extern NSString* const TAG_FILTERS;

extern NSString* const TAG_AUTO_SEND;

extern NSString* const TAG_SERVER_CAPTURE;
extern NSString* const TAG_SERVER_LOG_LEVEL;
extern NSString* const TAG_SERVER_FILTERS;

extern NSString* const KEY_DEVICEINFO_ENV;
extern NSString* const KEY_DEVICEINFO_OS_VERSION;
extern NSString* const KEY_DEVICEINFO_MODEL;
extern NSString* const KEY_DEVICEINFO_APP_NAME;
extern NSString* const KEY_DEVICEINFO_APP_VERSION;
extern NSString* const KEY_DEVICEINFO_DEVICE_ID;

extern NSString* const POST_METHOD;
extern NSString* const GET_METHOD;
extern NSString* const KEY_HEADER_WL_PREFIX;
extern NSString* const KEY_HEADER_WL_COMPRESSED;
extern NSString* const KEY_HEADER_CONTENT_TYPE;
extern NSString* const APPLICATION_JSON_HEADER;

extern NSString* const KEY_METADATA_SOURCE;
extern NSString* const KEY_METADATA_METHOD;
extern NSString* const KEY_METADATA_LINE;
extern NSString* const KEY_METADATA_FILE;
extern NSString* const KEY_METADATA_STACKTRACE;
extern NSString* const KEY_METADATA_MEMORY_USED;
extern NSString* const KEY_METADATA_MEMORY_FREE;
extern NSString* const KEY_METATDATA_DISKSPACE_USAGE;
extern NSString* const KEY_ARGUMENTS;
extern NSString* const KEY_METADATA_CATEGORY;
extern NSString* const KEY_METADATA_TYPE;
extern NSString* const KEY_METADATA_USER_METADATA;
extern NSString* const KEY_METADATA_DURATION;
extern NSString* const KEY_METADATA_TRACKING_ID;
extern NSString* const KEY_METADATA_URL;
extern NSString* const KEY_METADATA_BYTES_RECEIVED;
extern NSString* const KEY_METADATA_STATUS_CODE;

extern NSString* const KEY_METADATA_USER;
extern NSString* const KEY_METADATA_COLLECTION;
extern NSString* const KEY_METADATA_OPERATION;
extern NSString* const KEY_METADATA_START_TIME;
extern NSString* const KEY_METADATA_END_TIME;
extern NSString* const KEY_METADATA_RC;
extern NSString* const KEY_METADATA_SIZE;
extern NSString* const KEY_METADATA_IS_ENCRYPTED;

extern NSString* const SOURCE_SWIFT;
extern NSString* const SOURCE_OBJECTIVE_C;
extern NSString* const SOURCE_JAVASCRIPT;

extern NSString* const WORKLIGHT_PACKAGE;
extern NSString* const JSONSTORE_PACKAGE;
extern NSString* const JSONSTORE_ANALYTICS_PACKAGE;
extern NSString* const CERTMANAGER_PACKAGE;
extern NSString* const USERCERT_PACKAGE;
extern NSString* const WL_SECURITYUTILS_PACKAGE;
extern NSString* const SIMPLE_DATA_SHARING_PACKAGE;
extern NSString* const WL_DIRECT_UPDATE_PACKAGE;
extern NSString* const WL_SPLASH_PACKAGE;
extern NSString* const WL_INIT_PACKAGE;
extern NSString* const WL_ACTION_PACKAGE;
extern NSString* const WL_AUTH_PACKAGE;
extern NSString* const WL_CONFIG_PACKAGE;

extern NSString* const IMF_AUTH_PACKAGE;
extern NSString* const IMF_OAUTH_PACKAGE;
extern NSString* const IMF_REQUEST_PACKAGE;
extern NSString* const IMF_NAME;

extern NSString* const TAG_CATEGORY_EVENT;
extern NSString* const TAG_CATEGORY_NETWORK;

extern NSString* const TAG_SESSION;
extern NSString* const TAG_SESSION_ID;
extern NSString* const TAG_APP_STARTUP;

extern NSString* const KEY_EVENT_START_TIME;
extern NSString* const KEY_EVENT_END_TIME;
