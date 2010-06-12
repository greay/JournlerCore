//
//  JournlerCollection.h
//  JournlerCore
//
//  Created by Philip Dow on 08.08.05.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <Cocoa/Cocoa.h>
#import <JournlerCore/Definitions.h>
#import <JournlerCore/JournlerObject.h>

// collection type defintions
// ----------------------------------------------------------------------------------
#define PDCollectionTypeLibrary		@"01-Library"
#define PDCollectionTypeTrash		@"09-Trash"
#define PDCollectionTypeSmart		@"11-SmartFolder"
#define PDCollectionTypeFolder		@"21-Folder"

#define PDCollectionTypeIDLibrary		1
#define PDCollectionTypeIDTrash			50

#define PDCollectionTypeIDWriting		100
#define PDCollectionTypeIDImage			200
#define PDCollectionTypeIDAudio			300
#define PDCollectionTypeIDVideo			400
#define PDCollectionTypeIDDocuments		1000

#define PDCollectionTypeIDBookmark		500
#define PDCollectionTypeIDWebArchive	600
#define PDCollectionTypeIDPDF			700

#define PDCollectionTypeIDSmart			800
#define PDCollectionTypeIDFolder		900

#define PDCollectionTypeIDSeparator		-1

//
// 1.1 definitions
#define PDCollectionTag				@"tagID"
#define PDCollectionTitle			@"title"
#define PDCollectionType			@"type"
#define PDCollectionPreds			@"predicates"
#define PDCollectionComb			@"combinationStyle"
#define PDCollectionEntries			@"entries"

//
// 1.2 definitions
#define PDCollectionEntryIDs		@"entryIDs"
#define PDCollectionTypeID			@"typeID"

#define PDCollectionParentID		@"parentID"
#define PDCollectionParent			@"parent"

#define PDCollectionSortDescriptors	@"PDCollectionSortDescriptors"
#define PDCollectionLabel			@"PDCollectionLabel"

#define PDCollectionChildrenIDs		@"childrenIDs"
#define PDCollectionChildren		@"children"

#define PDCollectionImage			@"image"
#define PDCollectionImageSmall		@"imageSmall"

#define PDCollectionVersion			@"version"

#define PDCollectionIndex			@"index"

#define FolderWillAddEntryNotification			@"FolderWillAddEntryNotification"
#define FolderDidAddEntryNotification			@"FolderDidAddEntryNotification"

#define FolderWillRemoveEntryNotification		@"FolderWillRemoveEntryNotification"
#define FolderDidRemoveEntryNotification		@"FolderDidRemoveEntryNotification"

#define FolderWillBeginEvaluation				@"FolderWillBeginEvaluation"
#define FolderDidCompleteEvaluation				@"FolderDidCompleteEvaluation"



@class JournlerJournal;
@class JournlerEntry;

typedef enum {
	kJournlerFolderMenuDefaultSettings = 0,
	kJournlerFolderMenuIncludesEntries = 1 << 1,
	kJournlerFolderMenuUseLargeImages = 1 << 2
} JournlerFolderMenuRepresentationOptions;

@interface JournlerCollection : JournlerObject <NSCopying, NSCoding, NSMenuDelegate>
{
	NSMutableArray *entries;
	NSMutableArray *children;
	JournlerCollection *parent; // weak reference
	
	// cached predicate for smart folders
	NSPredicate *_actualPredicate;
	
	// dictionary of dynamically generated date conditions
	NSMutableDictionary *dynamicDatePredicates;
	
	BOOL isEvaluating;
	NSLock *entriesLock;
	
	// would love to move this into the method that uses it
	NSInteger menuRepresentationOptions;
}

+ (JournlerCollection*) separatorFolder;

#pragma mark -
#pragma mark parent

- (JournlerCollection*)parent;
- (void ) setParent:(JournlerCollection*)aCollection;

#pragma mark -
#pragma mark entries

- (NSArray*) entries;
- (void) setEntries:(NSArray*)anArray;

- (NSUInteger) countOfEntries;
- (id) objectInEntriesAtIndex:(NSUInteger)theIndex;
- (void) getEntries:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inEntriesAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromEntriesAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInEntriesAtIndex:(NSUInteger)theIndex withObject:(id)obj;

#pragma mark -
#pragma mark children

- (NSArray*) children;
- (void) setChildren: (NSArray*)anArray;

- (NSUInteger) countOfChildren;
- (id) objectInChildrenAtIndex:(NSUInteger)theIndex;
- (void) getChildren:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inChildrenAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromChildrenAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInChildrenAtIndex:(NSUInteger)theIndex withObject:(id)obj;

#pragma mark -

// Accessors for the children
- (void) addChild:(JournlerCollection*)subfolder atIndex:(NSUInteger)index;
- (void) removeChild:(JournlerCollection *)subfolder recursively:(BOOL)recursive;
- (void) moveChild:(JournlerCollection *)subfolder toIndex:(NSUInteger)anIndex;

- (NSArray*) allChildren;

#pragma mark -

- (BOOL) isEvaluating;
- (void) setIsEvaluating:(BOOL)evaluating;

- (NSArray*) entryIDs;
- (void) setEntryIDs:(NSArray*)entries;

- (NSMutableArray*) childrenIDs;
- (void) setChildrenIDs: (NSArray*)theChildren;

- (NSNumber*) parentID;
- (void) setParentID:(NSNumber*)theParent;

- (NSArray*) sortDescriptors;
- (void) setSortDescriptors:(NSArray*)anArray;

- (NSNumber*) label;
- (void) setLabel:(NSNumber*)aNumber;

- (NSNumber*) typeID;
- (void) setTypeID:(NSNumber*)newType;

- (NSNumber*) version;
- (void) setVersion:(NSNumber*)newVersion;

- (NSArray*) conditions;
- (void) setConditions:(NSArray*)newPredicates;

- (NSNumber*) combinationStyle;
- (void) setCombinationStyle:(NSNumber*)newStyle;

- (NSNumber*) index;
- (void) setIndex:(NSNumber*)index;

- (NSArray*) allConditions:(BOOL)grouped;

- (BOOL) autotagsKey:(NSString*)aKey;
- (BOOL) canAutotag:(JournlerEntry*)anEntry;
- (BOOL) autotagEntry:(JournlerEntry*)anEntry add:(BOOL)add;

// DEPRECATED
// pureType is used by the upgrade controller
- (NSString*) pureType;
// clearOldProperties is used by the upgrade controller
- (void) clearOldProperties;



- (void) sortChildrenByIndex; // IS THIS METHOD NECESSARY?


- (BOOL) generateDynamicDatePredicates:(BOOL)recursive;
- (void) invalidatePredicate:(BOOL)recursive;

- (NSString*) predicateString;
- (NSPredicate*) predicate;
- (NSPredicate*) effectivePredicate;

- (BOOL) evaluateAndAct:(id)object;
- (BOOL) evaluateAndAct:(id)object considerChildren:(BOOL)recursive;

- (void) _threadedEvaluateAndAct:(NSDictionary*)evalDict;

- (void) addEntry:(JournlerEntry*)entry;

- (void) removeEntry:(JournlerEntry*)entry;
- (void) removeEntry:(JournlerEntry*)entry considerChildren:(BOOL)recursive;

- (NSMenu*) menuRepresentation:(id)target 
		action:(SEL)aSelector 
		smallImages:(BOOL)useSmallImages 
		includeEntries:(BOOL)wEntries;
		
- (NSMenu*) undelegatedMenuRepresentation:(id)target 
		action:(SEL)aSelector 
		smallImages:(BOOL)useSmallImages 
		includeEntries:(BOOL)wEntries;
		
- (BOOL) flatMenuRepresentation:(NSMenu**)aMenu 
		target:(id)object 
		action:(SEL)aSelector 
		smallImages:(BOOL)useSmallImages 
		inset:(NSInteger)level;

// utilities

- (NSImage*) determineIcon;
+ (NSImage*) defaultImageForID:(NSInteger)type;

- (BOOL) isRegularFolder;
- (BOOL) isSmartFolder;
- (BOOL) isTrash;
- (BOOL) isLibrary;
- (BOOL) isSeparatorFolder;

- (BOOL) isDescendantOfFolder:(JournlerCollection*)node;
- (BOOL) isDescendantOfFolderInArray:(NSArray*)nodes;
- (BOOL) isMemberOfSmartFamilyConsideringSelf:(BOOL)includeSelf;

// used by [JournlerCollection copyWithZone:]
- (void) deepCopyChildrenToFolder:(JournlerCollection*)aFolder;

- (NSString*) packagePath;

- (BOOL) writeEntriesToFolder:(NSString*)directoryPath 
		format:(NSInteger)fileType 
		considerChildren:(BOOL)recursive 
		includeHeaders:(BOOL)headers;


// upgrade methods
- (void) updateForTwoZero;
- (void) perform253Maintenance;

@end

@interface JournlerCollection (JournlerScriptability)

- (OSType) scriptType;
- (void) setScriptType:(OSType)osType;

- (OSType) scriptLabel;
- (void) setScriptLabel:(OSType)osType;

- (NSNumber*) scriptCanAutotag;

#pragma mark -

- (NSUInteger) indexOfObjectInJSEntries:(JournlerEntry*)anEntry;
- (NSUInteger) countOfJSEntries;
- (JournlerEntry*) objectInJSEntriesAtIndex:(NSUInteger)anIndex;
- (JournlerEntry*) valueInJSEntriesWithUniqueID:(NSNumber*)anId;

- (NSUInteger) indexOfObjectInJSFolders:(JournlerCollection*)aFolder;
- (NSUInteger) countOfJSFolders;
- (JournlerCollection*) objectInJSFoldersAtIndex:(NSUInteger)anIndex;
- (JournlerCollection*) valueInJSFoldersWithUniqueID:(NSNumber*)anId;

#pragma mark -

- (void) jsExport:(NSScriptCommand *)command;
- (void) jsAddFolderToFolder:(NSScriptCommand *)command;
- (void) jsMoveFolderToFolder:(NSScriptCommand *)command;

@end
