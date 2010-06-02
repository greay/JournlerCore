//
//  JournlerResource.h
//  JournlerCore
//
//  Created by Philip Dow on 10/26/06.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

/*!
	@class JournlerResource
	@abstract Wraps the various kinds of data that may be attached to an entry
	@discussion The JournlerResource class manages the many kinds of data
		that may be attached to entries. Data types include URLs, Address Book
		Records, other Journler objects and files. Support for iCal events
		should be available for the 2.6 iteration.
		
		
*/

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

#import <JournlerCore/JournlerObject.h>
#import <JournlerCore/Definitions.h>

typedef NSUInteger JournlerResourceType;

enum {
	kResourceTypeFile = 1,
	kResourceTypeURL = 2,
	kResourceTypeABRecord = 3,
	kResourceTypeJournlerObject = 4
};

typedef NSUInteger NewResourceCommand;

enum {
	kNewResourceUseDefaults = NSDragOperationGeneric,
	kNewResourceForceLink = NSDragOperationLink,
	kNewResourceForceCopy = NSDragOperationCopy,
	kNewResourceForceMove = NSDragOperationMove
};

enum {
	kJournlerResourceAliasBadge = 0,
	kJournlerResourceQuestionMarkBadge,
	kJournlerResourceBlankDocumentIcon,
	kJournlerResourceAlertBadge
};

#define ResourceUnknownUTI					@"com.journler.unknown"
#define ResourceJournlerObjectURIUTI		@"com.jourlner.uri"
// this is misspelled -- should be "com.journler.uri"

#define ResourceURLUTI						@"com.journler.url"
	// DEPRECATED -> kUTTypeURL
#define ResourceABPersonUTI					@"com.journler.abperson"
	// DEPRECATED -> kUTTypeJournlerABPerson (not yet deprecated)

#define kUTTypeJournlerABPerson				@"com.apple.addressbook.person"

#define kUTTypeJournlerEntry				@"com.sprouted.journler.entry"
#define kUTTypeJournlerFolder				@"com.sprouted.journler.folder"

#define kUTTypeJournlerObjectWrapper		@"com.sprouted.journler.object-wrapper"

#define kUTTypeJournlerMailEmailExtended	@"com.apple.mail.emlx"
#define kUTTypeJournlerMailEmail			@"com.apple.mail.email"

#define kUTTypeJournlerChatChat				@"com.apple.ichat.ichat"
#define kUTTypeJournlerChatTranscript		@"com.apple.ichat.transcript"

@class JournlerJournal;
@class JournlerEntry;

@interface JournlerResource : JournlerObject <NSCopying, NSCoding>
{
	// relationships
	JournlerEntry *entry;
	NSMutableArray *entries;
	
	// used when re-establishing the entry-resource relationships during load
	NSArray *entryIDs;
	NSNumber *owningEntryID;
	
	// applescript
	NSNumber *scriptAliased;
	
	// searching
	float relevance;
	
	// icon memory management
	NSInteger _previewRetainCount;
	NSTimeInterval _lastPreviewAccess;
}

+ (NSArray*) definedUTIs;

/*!
	@function entry
	@abstract The parent entry with which a resource is associated.
	@discussion While a resource may be associated with many entries, it is
		also always connected to a single, default entry that serves as its parent.
		Usually this is the first entry to which a resource was assigned.
		It can change when, for example, a resource has been linked to another
		entry and the first entry is deleted.
	@result An array of JournlerEntry objects.
*/

- (JournlerEntry*) entry;

/*!
	@function setEntry:
	@abstract Sets the parent entry with which the receiver is associated.
	@discussion See the discussion for the entry method above.
	@param anEntry A JournlerEntry object which will serve as the receiver's default entry.
*/

- (void) setEntry:(JournlerEntry*)anEntry;

#pragma mark -
#pragma mark entries

/*!
	@function entries
	@abstract The entries with which the receiver is associated.
	@discussion The entries array identifies the entries to which the receiver is attached
		A JournlerResource may be linked to more than one entry.
	@result An array of JournlerEntry objects
*/

- (NSArray*) entries;

/*!
	@function setEntries:
	@abstract Sets the entries with which the receiver is associated.
	@discussion The entries array identifies the entries to which the receiver is attached
		A JournlerResource may be linked to more than one entry.
		
		Do not use this method to modify a resource's associated entries.
		If you are adding a resource to an entry, use the JournlerEntry method addResource:.
		
		If you are deleting a resource from an entry, use the JournlerJournal method
		removeResources:fromEntries:errors:. This method ensures that the complex
		relationships between a resource and its associated entries are kept in a consistent
		state.
		@param anArray An array of JournlerEntry objects
*/

- (void) setEntries:(NSArray*)anArray;

/*
	The following methods allow for mutable access to a resources's entry array
*/

- (NSUInteger) countOfEntries;
- (id) objectInEntriesAtIndex:(NSUInteger)theIndex;
- (void) getEntries:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inEntriesAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromEntriesAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInEntriesAtIndex:(NSUInteger)theIndex withObject:(id)obj;

#pragma mark -

- (NSArray *) entryIDs;
- (void) setEntryIDs:(NSArray*)anArray;

- (NSNumber *) owningEntryID;
- (void) setOwningEntryID:(NSNumber*)aNumber;

#pragma mark -

- (JournlerResourceType) type JOURNLER_DEPRECATED;
- (void) setType:(JournlerResourceType)aResourceType;

- (NSNumber*) searches;
- (void) setSearches:(NSNumber*)search;

- (NSNumber*) label;
- (void) setLabel:(NSNumber*)aNumber;

- (NSString*) uti;
- (void) setUti:(NSString*)aString;

- (NSArray*) utisConforming;
- (void) setUtisConforming:(NSArray*)anArray;

- (NSString*) allUTIs;
- (NSArray*) allUTIsArray;

// plain text representation of the receiver, used when performing searches

- (NSString*) textRepresentation;
- (void) setTextRepresentation:(NSString*)aString;

// the last modification date of the underlying data, 
// ie a file's mod date rather than when the resource was last changed in Journler

- (NSDate*) underlyingModificationDate;
- (void) setUnderlyingModificationDate:(NSDate*)aDate;

- (float) relevance;
- (void) setRelevance:(float)aValue;

#pragma mark -

- (BOOL) representsFile;
- (BOOL) representsURL;
- (BOOL) representsABRecord;
- (BOOL) representsJournlerObject;

- (BOOL) isEqualToResource:(JournlerResource*)aResource;

#pragma mark -

/*!
	@function urlRepresentation
	@abstract Returns a URL representation of the receiver.
	@discussion urlRepresentation returns a URL representation of the JournlerResource
		that uniquely identifies the underlying data. In the case of files, for example, 
		a file URL pointing to the original document is returned. For Address Book records,
		the method returns a unique id url whose absolute string is comprehensible to
		the Address Book Framework.
		
		The resource's URL representation is passed to the various media plugins
		and interpreted by them to determine what data will be displayed.
	@result An NSURL object that identifies the data wrapped by the receiver
*/

- (NSURL*) urlRepresentation;

#pragma mark -

- (void) loadIcon;
- (void) cacheIconToDisk;
- (void) reloadIcon;
- (void) addMissingFileBadge;
- (NSString*) createFileAtDestination:(NSString*)path;

#pragma mark -

/*!
	@function revealInFinder
	@abstract Reveals the receiver in the Finder.
	@discussion Files will be displayed in a Finder window. The method passes
		most other resources to the openWithFinder method.
*/

- (void) revealInFinder;

/*!
	@function openWithFinder
	@abstract Opens the receiver in a manner appropriate to the underlying data.
	@discussion Files will be opened in their respective applications. URLs
		are launched in the default web browser, Address Book contacts displayed
		in Address Book, iCal events in iCal and so on.
*/

- (void) openWithFinder;

#pragma mark -

- (NSString*) _thumbnailPath;
- (NSImage*) _iconForFileResource;
- (void) _deriveTextRepresentation:(NSString*)filename;

#pragma mark -

- (void) retainPreview;
- (void) releasePreview;
- (NSInteger) previewRetainCount;
- (NSTimeInterval) lastPreviewAccess;
- (void) unloadPreview;
- (NSImage*) previewIfLoaded;

#pragma mark -

- (void) perform253Maintenance;

@end

@interface JournlerResource (FileResource)

- (id) initFileResource:(NSString*)path;

- (NSString*) filename;
- (void) setFilename:(NSString*)aString;

- (NSString*) relativePath;
- (void) setRelativePath:(NSString*)aString;

- (NSString*) path;
- (NSString*) originalPath;

- (BOOL) isAlias;

- (BOOL) isDirectory;
- (BOOL) isFilePackage;

- (BOOL) isAppleScript;
- (BOOL) isApplication;

+ (NSImage*) iconBadgeForBadgeId:(NSInteger)type;

@end

@interface JournlerResource (URLResource)

- (id) initURLResource:(NSURL*)aURL;

- (NSString*) urlString;
- (void) setUrlString:(NSString*)aString;

- (NSString*) searchContentForURL;
- (NSString*) htmlRepresentationForURLWithCache:(NSString*)cachePath;

@end

@interface JournlerResource (ABPersonResource)

- (id) initABPersonResource:(ABPerson*)aPerson;

- (NSString*) uniqueId;
- (void) setUniqueId:(NSString*)aString;

- (ABPerson*) person;
- (NSString*) searchContentForABRecord;

@end

@interface JournlerResource (JournlerObjectResource)

- (id) initJournalObjectResource:(NSURL*)aURI;

- (NSString*) uriString;
- (void) setUriString:(NSString*)aString;

- (id) journlerObject;

@end

@interface JournlerResource (PasteboardSupport)

- (id) initWithPasteboard:(NSPasteboard*)pboard operation:(NewResourceCommand)command 
		entry:(JournlerEntry*)anEntry journal:(JournlerJournal*)aJournal;

@end

@interface JournlerResource (JournlerScriptability)

- (OSType) scriptType;
- (void) setScriptType:(OSType)osType;

- (OSType) scriptLabel;
- (void) setScriptLabel:(OSType)osType;

- (NSNumber*) scriptAliased;
- (void) setScriptAliased:(NSNumber*)aNumber;

#pragma mark -

- (NSInteger) indexOfObjectInJSEntries:(JournlerEntry*)anEntry;
- (NSUInteger) countOfJSEntries;
- (JournlerEntry*) objectInJSEntriesAtIndex:(NSUInteger)i;
- (JournlerEntry*) valueInJSEntriesWithUniqueID:(NSNumber*)idNum;

//- (NSScriptObjectSpecifier *)objectSpecifier;

#pragma mark -

- (void) jsExport:(NSScriptCommand *)command;

@end
