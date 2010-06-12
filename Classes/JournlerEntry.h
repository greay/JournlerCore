//
//  JournlerEntry.h
//  JournlerCore
//
//  Created by Philip Dow on xx.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//


#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#import <AddressBook/AddressBook.h>

#import <JournlerCore/JournlerObject.h>
#import <JournlerCore/JournlerResource.h>

#define PDEntryTitle				@"Entry Title"
#define PDEntryCategory				@"Entry Category"
#define PDEntryKeywords				@"Entry Keywords"
#define PDEntryTag					@"Entry Tag"
#define PDEntryBlogs				@"Entry Blogs"
#define PDEntryFlagged				@"Entry Flagged"
#define PDEntryLabelColor			@"Entry Label Color"
#define PDEntryAtttibutedContent	@"Entry Attributed Content"
#define PDEntryCalDate				@"Entry Cal Date"
#define PDEntryCalDateModified		@"Entry Cal Date Modified"
#define PDEntryCalDateDue			@"Entry Cal Date Due"
#define PDEntryVersion				@"Entry Version Number"
#define PDEntryMarkedForTrash		@"Entry Marked For Trash"

#define PDEntryResourceIDs			@"PDEntryResourceIDs"

//2.5.4
#define PDEntryComments				PDEntryKeywords
#define PDEntryTags					@"Entry Tags"

//
// deprecated
#define PDEntryDateModified			@"Entry Date Modified"
#define PDEntryDate					@"Entry Date"
#define PDEntryTimestamp			@"Entry Timestamp"
#define PDEntryRTFD					@"Entry RTFD"
#define PDEntryViewMode				@"Entry View Mode"
#define PDEntrySelectedMediaURL		@"EntryMediaURL"
#define PDEntryStringValue			@"EntryStringValue"
#define PDEntrySearchMedia			@"PDEntrySearchMedia"
#define PDEntryLastSelectedResource	@"EntryLastSelectedResource"

//
// for storing an entrys data in the file package
#define PDEntryPackageEncrypted					@".encrypted"
#define	PDEntryPackageEntryContents				@"Contents.jobj"
#define PDEntryPackageRTFDContent				@"Entry.rtfd"
#define PDEntryPackageRTFDContainer				@"_Text.jrtfd"
#define PDEntryPackageResources					@"Resources"


#define EntryWillAddResourceNotification		@"EntryWillAddResourceNotification"
#define EntryDidAddResourceNotification			@"EntryDidAddResourceNotification"

#define EntryWillRemoveResourceNotification		@"EntryWillRemoveResourceNotification"
#define EntryDidRemoveResourceNotification		@"EntryDidRemoveResourceNotification"

typedef enum {

	kEntrySaveAsRTF = 0,
	kEntrySaveAsWord = 1,
	kEntrySaveAsRTFD = 2,
	kEntrySaveAsPDF = 3,
	kEntrySaveAsHTML = 4,
	kEntrySaveAsText = 5,
	kEntrySaveAsiPodNote = 6,
	kEntrySaveAsPackage = 7,
	kEntrySaveAsWebArchive = 8
	
} EntrySaveFileTypes;

enum {
	kEntrySetFileCreationDate = 1 << 1,
	kEntrySetFileModificationDate = 1 << 2,
	kEntryIncludeHeader = 1 << 3,
	kEntrySetLabelColor = 1 << 4,
	kEntryHideExtension = 1 << 5,
	kEntryDoNotOverwrite = 1 << 6
} EntrySaveFlags;

enum {
	kEntryImportIncludeIcon = 1 << 1,
	kEntryImportSetDefaultResource = 1 << 2,
	kEntryImportPreserveDateModified = 1 << 3
} EntryImportOptions;

@class BlogPref;
@class JournlerJournal;
@class JournlerResource;

@interface JournlerEntry : JournlerObject <NSCopying, NSCoding, NSTextStorageDelegate>
{
	
	//
	// The JournlerEntry instance variables.
	//
	//		// Do not modify these variables directly
	//		// Use the appropriate accessors to alter the entry's contents
	//
	
	// relationships
	NSMutableArray *collections;
	NSMutableArray *resources;
	
	// used when re-establishing the entry-resource relationships during load
	NSArray *resourceIDs;
	NSNumber *lastResourceSelectionID;
	
	// container for AppleScript support
	NSTextStorage *scriptContents;
	
	// relevance is used during searching
	float relevance;
	
	// the date integer is an integer representation of an entry's date,
	// cached to speed up the calendar and smart folders. It is regenerated
	// whenever the date changes
	NSInteger _dateInt;
	
	// used internally during file imports, necessary in Journler 2.0 due to
	// the way Journler packages entries
	NSString *_import_path;
	NSDate *_importModificationDate;
	
	//
	NSString *_resourceTypesCached;
	
	
	NSInteger _contentRetainCount;
	NSTimeInterval _lastContentAccess;
	
	// indicates whether an entry is encrypted or not. 
	// DEPCREATED
	NSNumber *encrypted;
}

//
// The Journler initializers
//
//		// Your plugin should not need to call these methods
//

- (id) initWithPath:(NSString*)path;

//
//
// relationships

#pragma mark -
#pragma mark collections

- (NSArray*) collections;
- (void) setCollections:(NSArray*)anArray;

- (NSUInteger) countOfCollections;
- (id) objectInCollectionsAtIndex:(NSUInteger)theIndex;
- (void) getCollections:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inCollectionsAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromCollectionsAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInCollectionsAtIndex:(NSUInteger)theIndex withObject:(id)obj;

#pragma mark -
#pragma mark Resources

// resources describes references to other files, contacts, urls, etc
- (NSArray*) resources;
- (void) setResources:(NSArray*)anArray;

- (NSUInteger) countOfResources;
- (id) objectInResourcesAtIndex:(NSUInteger)theIndex;
- (void) getResources:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inResourcesAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromResourcesAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInResourcesAtIndex:(NSUInteger)theIndex withObject:(id)obj;

#pragma mark -

- (NSArray*) resourceIDs;
- (void) setResourceIDs:(NSArray*)anArray;

- (NSNumber*) lastResourceSelectionID;
- (void) setLastResourceSelectionID:(NSNumber*)aNumber;

#pragma mark -

//
// The NSString date indicates the date to which the entry belongs
//
//		// Deprecated. Do not use this method any more
//		// Use calDate instead, which returns an NSCalendarDate object
//

- (NSString*) date JOURNLER_DEPRECATED;

//
// The NSString title is the entry's title
//
//		// The title is often the most important means of entry identification
//		// If the user is running Tiger, smart folders can identify an entry by its timestamp
//		// The title can be any string and can include unicode characters
//		// Entries are not stored by title, so more than one entry can have the same title
//
//		// The pathSafeTitle filters an entry's title for against reserved characters
//		// You could use it when exporting the entry content's to a separate file
//
//		// previouslySavedTitle is a utility method used by the journal when saving
//		// a renamed entry. You do not need to use it, and do not change it.
//

- (NSString*) wikiTitle;

//
// The calDate and calDateModified properties place an entry at a dated location
// ( New in Journle 2.0 - they replace the date and dateModified properties )
//
//		// calDate and calDateModified use NSCalendarDate objects
//		// The date and dateModified methods are deprecated. Do not use them.
//	
//		// Be careful NOT to use NSDate objects. NSCalendarDate objects are expected
//		// To convert an NSDate to an NSCalendarDate, use NSDate's
//		//		dateWithCalendarFormat:timeZone - you may pass nil for both parameters
//

- (NSCalendarDate*) calDate;
- (void) setCalDate:(NSCalendarDate*)date;

- (NSCalendarDate*) calDateModified;
- (void) setCalDateModified:(NSCalendarDate*)date;

- (NSCalendarDate*) calDateDue;
- (void) setCalDateDue:(NSCalendarDate*)date;

//
// The NSString category is the entry's abstract category
//
//		// The category is an abstract way of grouping the entry with other entries
//		// Standard categories include Personal, Dreams, and Work, etc
//		// If the user is running Tiger, smart folders can identify an entry by its category
//		// The category can be any string and can include unicode characters
//

- (NSString*) category;
- (void) setCategory:(NSString*)newObject;

//
// The NSString keywords is a further means of abstractly handling an entry
//
//		// The keywords property quickly identifies an entry by key concepts it deals with
//		// The user can format the string in any way, ie a comma separated list or a complete sentence
//		// If the user is running Tiger, smart folders can identify an entry by its keywords
//		// The keywords string can be any string and can include unicode characters
//

- (NSString*) keywords;
- (void) setKeywords:(NSString*)newObject;

// as of 2.5.4, keywords then referred to as tags become comments
- (NSString*) comments;
- (void) setComments:(NSString*)newObject;

//
// as of 2.5.3, tags as an array takes over from keywords/tags as a string

- (NSArray*) tags;
- (void) setTags:(NSArray*)newObject;

//
// The attributedContent is the entry's main content as an attributed string object
// ( New in Journler 2.0 - the 1.x format used rich text data )
//
//		// ************
//		// Your plugin subclass will most likely need to focus on this property
//		// ************
//

- (NSAttributedString*) attributedContent;
- (void) setAttributedContent:(NSAttributedString*)content;

// returns the attributed content if it's loaded, nil otherwise
- (NSAttributedString*) attributedContentIfLoaded;

- (BOOL) loadAttributedContent;
- (NSString*) attributedContentPath;

// increments the retain count on the attributed content
// if you're using the attributed content you should call this method to prevent journler from emptying the cache
// at an unspecified interval

- (void) retainContent;
- (void) releaseContent;
- (NSInteger) contentRetainCount;
- (NSTimeInterval) lastContentAccess;
- (void) unloadAttributedContent;

//
//
//

- (JournlerResource*) selectedResource;
- (void) setSelectedResource:(JournlerResource*)aResource;

//
// The version identifies an entry's formatting as an integer value
// ( New in Journler 2.0 )
//
//		// The current version number is 120.
//		// A more appropriate value would be 200, but Journler 2.0 was originally 1.2
//

- (NSNumber*)version;
- (void) setVersion:(NSNumber*)verNum;

//
// markedForTrash indicates an entry's "trashed" status
//
//		// When an entry is deleted from a date or the journal collection, 
//		// it is placed in the trash
//		// Entries are only permanently removed when they are deleted from the trash 
//		// or when the trash is emptied
//

- (NSNumber*) markedForTrash;
- (void) setMarkedForTrash:(NSNumber*)mark;

//
// The NSArray blogs property contains a list of blogs to which this entry has been posted
//
//		// The blogs array contains BlogPref objects
//
//		// You should not modify this property yet. I need to make further changes
//		// to blog tracking first
//

- (NSArray*) blogs;
- (void) setBlogs:(NSArray*)newObject;

//
// flagged provides an  way of marking an entry.
//
//		// The user can flag an entry for any reason, a personal way of assigning significance 
//		// Smart folders can filter entries based on the flag property
//

- (NSNumber*) marked;
- (void) setMarked:(NSNumber*)aValue;

- (NSInteger) markedInt;
- (void) setMarkedInt:(NSInteger)aValue;

- (NSNumber*) flagged;
- (void) setFlagged:(NSNumber*)flagValue;

- (BOOL) flaggedBool;
- (void) setFlaggedBool:(BOOL)flagValue;

- (BOOL) checkedBool;
- (void) setCheckedBool:(BOOL)aValue;

//
// The label provides yet another way of marking an entry.
//
//		// The user can label an entry for any reason, a personal way of assigning significance 
//		// Smart folders can filter entries based on the label property
//		// A label's value runs from 0 to 6, 0 is none while 1 through 6 indicate color
//

- (NSNumber*) label;
- (void) setLabel:(NSNumber*)val;

//
// The float relevance is an entry's relevance during toolbar searching
//
//		// Your plugin should not modify this value
//		// Relevance comes and goes as the search query changes
//		// The relevance value is not cleared after a search, do not rely on its value
//

- (float) relevance;
- (void) setRelevance:(float)nr;

//
// The NSString relevanceString and NSNumber relevanceNumber are an entry's relevance as cocoa objects
//
//		// Your plugin should not need to operate on these value
//		// Relevance comes and goes as the search query changes
//		// The relevance value is not cleared after a search, do not rely on its value
//		// Utility methods to convert the actual relevance into a useful cocoa object
//

- (NSNumber*) relevanceNumber;

//
// The integers dateInt, timeInt and dateModifiedInt indicate the date and time in integer format
//
//		// Smart folders use this information to quickly assess one entry's date or time
//		   relationship to another, ie before, after, or on
//		// An entry whose date is January 12th 2005 will have a dateInt value of 20050112
//		// the dateInt value is cached because it is used so often
//

- (NSInteger) dateInt;
- (NSInteger) dateModifiedInt;
- (NSInteger) dateCreatedInt;
- (NSInteger) dateDueInt;

/*!
	@function generateDateInt
	@abstract Creates an integer representation of the date and caches it
	@discussion An entry's date of creation is used extensively in Journler.
		This method creates an integer representation of the NSDate dateCreated attribute
		so that it can be quickly accessed and compared to other entry dates. The cache is in the format
		 %Y%m%d or YYYYMMDD. 
		 
		 You should not need to call this method. The date integer is created when a Journler entry object
		 is initalized and when its date of creation is changed.
*/


- (void) generateDateInt;

- (NSInteger) labelInt;

//
// The boolean blogged quickly indicates whether an entry has been blogged or not
//
//		// The method simply looks at the blogs array and returns true if the count is greater than zero
//		// Smart folders use this information to determine an entry's blogged status
//		// setBlogged: does nothing but provides a cheat for key-value observing
//

- (BOOL) blogged;
- (void) setBlogged:(BOOL)isBlogged;

//
// The content value is the same as returned by stringValue
// entireEntry returns a string representation of the entry's title, category, keywords and content
//
//		// These methods are utility methods used during searching.
//		// Use them if you need a string representation of an entry
//

- (NSString*) content;
- (NSString*) entireEntry;

//
// The defaultTextAttributes is a starting point for an entry's textual attributes
//
//		// defaultTextAttributes provides the user defined font, color and paragraph attributes
//		// for new entries. Use these values if you are adding plain text content to an entry
//
//		// Better yet, examine the attributes at the point where you are inserting the text
//		// and use those.
//

+ (NSDictionary*) defaultTextAttributes;

//
// The performOneTwoMaintenance method is a utility used during the 1.1 -> 2.0 conversion
//
//		// Do not call this method.
//		// It may have no effect or it may produce unexpected results
//

- (BOOL) performOneTwoMaintenance:(NSMutableString**)log;
- (void) perform210Maintenance;
- (void) perform253Maintenance;

- (NSString*) searchableContent;
- (NSDictionary*) metadata;

- (void) deriveTitleFromContent;

//
// for including entries with specific resources in smart folders

- (NSString*) allResourceTypes;
- (void) setAllResourceType:(NSString*)aString;

- (void) invalidateResourceTypes;

#pragma mark -
#pragma mark Deprecated Methods

// DEPRECATED
- (NSNumber*) labelValue JOURNLER_DEPRECATED;
- (void) setLabelValue:(NSNumber*)aNumber JOURNLER_DEPRECATED;

- (BOOL) hasBlog:(id)whichBlog JOURNLER_DEPRECATED;
- (void) addBlog:(id)whichBlog JOURNLER_DEPRECATED;

- (NSNumber*) encrypted JOURNLER_DEPRECATED;
- (void) setEncrypted:(NSNumber*)encrypt JOURNLER_DEPRECATED;

// END --------------------------------------------------------

@end

#pragma mark -

@interface JournlerEntry (ResourceAndMediaManagement)

/*!
	@function resourceForABPerson:
	@abstract Creates a resource wrapping the ABPerson data and attaches it to the receiver
	@discussion Convinience method for quickly creating new Address Book resources
		and attaching them to the specified entry. If the Person has already been
		attached to another entry, the method avoids duplicating the resource. Otherwise
		a new resource is created and the necessary relationships are established.
	@param aPerson A JournlerResource object that will be associated with the receiver.
	@result JournlerResource corresponding to the new resource object or a previously
		existing one
*/

- (JournlerResource*) resourceForABPerson:(ABPerson*)aPerson;

/*!
	@function resourceForURL:title:
	@abstract Creates a resource wrapping the url and title and attaches it to the receiver
	@discussion Convinience method for quickly creating new URL resources
		and attaching them to the specified entry. If the URL has already been
		attached to another entry, the method avoids duplicating the resource. Otherwise
		a new resource is created and the necessary relationships are established.
	@param urlString A string representation of a url
	@param title The title of the url, eg the title of a web page
	@result JournlerResource corresponding to the new resource object or a previously
		existing one
*/

- (JournlerResource*) resourceForURL:(NSString*)urlString title:(NSString*)title;

/*!
	@function resourceForFile:operation:
	@abstract Creates a resource wrapping the file and attaches it to the receiver
	@discussion Convinience method for quickly creating new file resources
		and attaching them to the specified entry. If the file has already been
		attached to another entry, the method avoids duplicating the resource. Otherwise
		a new resource is created and the necessary relationships are established.
	@param path The full path to the file the resources should wrap
	@param operation Specifies whether the underlying document is copied into the
		journal's directory or if an alias is established to it. Refer to the 
		NewResourceCommand constants for more information.
	@result JournlerResource corresponding to the new resource object or a previously
		existing one
*/

- (JournlerResource*) resourceForFile:(NSString*)path operation:(NewResourceCommand)operation;

/*!
	@function resourceForJournlerObject:
	@abstract Creates a resource wrapping a Journler object and attaches it to the receiver
	@discussion Convinience method for quickly creating new Journler object resources
		and attaching them to the specified entry. If the object has already been
		attached to another entry, the method avoids duplicating the resource. Otherwise
		a new resource is created and the necessary relationships are established.
	@param anObject The JournlerEntry or JournlerFolder being added to the entry.
	@result JournlerResource corresponding to the new resource object or a previously
		existing one
*/

- (JournlerResource*) resourceForJournlerObject:(id)anObject;

/*!
	@function addResource:
	@abstract Associated a JournlerResource object with the receiver.
	@discussion A JournlerEntry may be linked with an indefinite number of resources.
		This method attachess a JournlerResource to a JournlerEntry if the
		resource is not already associated with it. Although the resources
		relationship is marked as an array it is maintained internally as though it were
		a set.
	@param aResource A JournlerResource object that will be associated with the receiver.
	@result JournlerResource The actual resource added to the entry. I don't recall
		why I included this return value. I believe the returned resource will always
		be the same wether the resource was already attached to the entry or not.
*/

- (JournlerResource*) addResource:(JournlerResource*)aResource;

/*!
	@function removeResource:
	@abstract Removes a JournlerResource object from the receiver.
	@discussion Disassociates a resource from the receiver. This method does not
		delete the resource and it does not re-configure the resource's other relationships
		to ensure the resource continues to have a default parent entry. 
		Consequently, you should not use this method to remove a resource from an entry.
		Instead call the JournlerJournal method removeResources:fromEntries:errors:
	@param aResource A JournlerResource that will be removed with the receiver.
	@result bool indicating if th eoperation was successful.
*/

- (BOOL) removeResource:(JournlerResource*)aResource;

- (BOOL) resourcesIncludeFile:(NSString*)filename;

// what was I using this from?
- (NSArray*) textualLinks JOURNLER_DEPRECATED;

// replacement methods used in 2.1
- (NSString*) packagePath;
- (NSString*) resourcesPathCreating:(BOOL)create;

#pragma mark -
#pragma mark Deprecated methods

// DEPRECATED (from 2.0)
- (NSString*) pathToPackage JOURNLER_DEPRECATED;

// DEPRECATED
- (NSURL*) fileURLForResourceURL:(NSURL*)url; // used by the upgrade controller
- (NSURL*) fileURLForResourceFilename:(NSString*)filename; // used by fileURLForResourceURL

@end

#pragma mark -

@interface JournlerEntry (InterfaceSupport)

+ (BOOL) canImportFile:(NSString*)fullpath;

- (id) initWithImportAtPath:(NSString*)fullpath 
		options:(NSInteger)importOptions 
		maxPreviewSize:(NSSize)maxSize;
		
- (BOOL) completeImport:(NSInteger)importOptions 
		operation:(NewResourceCommand)operation 
		maxPreviewSize:(NSSize)maxSize;

- (BOOL) writeToFile:(NSString*)path 
		as:(NSInteger)saveType 
		flags:(NSInteger)saveFlags;

- (NSAttributedString*) prepWithTitle:(BOOL)wTitle 
		category:(BOOL)wCategory 
		smallDate:(BOOL)wDate;

- (BOOL) _writeiPodNote:(NSString*)contents iPod:(NSString*)path;

@end

#pragma mark -

@interface JournlerEntry (PreferencesSupport)

+ (BOOL) modsDateModdedOnlyOnTextualChange;
+ (NSString*) defaultCategory;
+ (NSString*) dropBoxCategory;

@end

@interface JournlerEntry (JournlerScriptability)

- (NSTextStorage*) contents;
- (void) setContents:(id)anObject;

- (NSAttributedString*) processScriptSetContentsForLinks:(NSAttributedString*)anAttributedString;

- (OSType) scriptLabel;
- (void) setScriptLabel:(OSType)osType;

- (OSType) scriptMark;
- (void) setScriptMark:(OSType)osType;

- (NSDate*) dateCreated;
- (void) setDateCreated:(NSDate*)aDate;

- (NSDate*) dateModified;
- (void) setDateModified:(NSDate*)aDate;

- (NSDate*) dateDue;
- (void) setDateDue:(NSDate*)aDate;

- (NSString*) htmlString;

- (JournlerResource*) scriptSelectedResource;
- (void) setScriptSelectedResource:(id)anObject;

//
// The NSString stringValue is the entry's RTFD content as a string
//
//		// The method converts only the attributed content into string object
//		// Use this method to quickly access an entry's string content when you do not
//		   need all the information containted in an attributed string
//

- (NSString*) stringValue;
- (void) setStringValue:(id)sv;

#pragma mark -

- (NSInteger) indexOfObjectInJSReferences:(JournlerResource*)aReference;
- (NSUInteger) countOfJSReferences;
- (JournlerResource*) objectInJSReferencesAtIndex:(NSUInteger)i;
- (JournlerResource*) valueInJSReferencesWithUniqueID:(NSNumber*)idNum;

#pragma mark -

- (void) jsExport:(NSScriptCommand *)command;
- (void) jsAddEntryToFolder:(NSScriptCommand *)command;
- (void) jsRemoveEntryFromFolder:(NSScriptCommand *)command;

@end