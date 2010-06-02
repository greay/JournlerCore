//
//  Definitions.h
//  JournlerCore
//
//  Created by Philip Dow on 12.08.05.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <Cocoa/Cocoa.h>
// NSAppleScriptErrorNumber
#define kScriptWasCancelledError	-128

// macros
// ----------------------------------------------------------------------------------

#define defaultBool(x) [[NSUserDefaults standardUserDefaults]boolForKey:x]
#define BeepAndBail() NSBeep(); return
#define BeepAndBoolBail(x) NSBeep(); return x

#define TempDirectory() ( NSTemporaryDirectory() != nil ? NSTemporaryDirectory() : [NSString stringWithString:@"/tmp"] )

#define WebURLsWithTitlesPboardType @"WebURLsWithTitlesPboardType"
#define kMVMessageContentsPboardType @"MVMessageContentsPboardType"

typedef enum {
	kOpenMediaIntoTab = 0,
	kOpenMediaIntoWindow = 1,
	kOpenMediaIntoFinder = 2
} OpenMediaIntoPreference;


// pasteboard defintions
// ----------------------------------------------------------------------------------
#define PDEntryIDPboardType		@"PDEntryIDPboardType"
#define PDFolderIDPboardType	@"PDFolderIDPboardType"
#define PDResourceIDPboardType	@"PDResourceIDPboardType"


#define PDAutosaveNotification	@"PDAutosaveNotification"


// ----------------------------------------------------------------------------------

#if defined(__GNUC__) && ((__GNUC__ >= 4) || ((__GNUC__ == 3) && (__GNUC_MINOR__ >= 1)))
    #define JOURNLER_DEPRECATED __attribute__((deprecated))
#else
    #define JOURNLER_DEPRECATED
#endif