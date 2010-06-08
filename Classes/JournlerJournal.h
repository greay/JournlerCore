//
//  JournlerJournal.h
//  JournlerCore
//
//  Created by Philip Dow on xx.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>

#import <JournlerCore/Definitions.h>
#import <JournlerCore/JournlerResource.h>

#define PDJournalPropertiesLoc		@"Journler.plist"
#define PDJournalStoreLoc			@"JournlerStore.dict"

#define PDEntriesLoc				@"Journler Entries"
#define PDCollectionsLoc			@"Collections"
#define PDJournalBlogsLoc			@"Blogs"
#define PDJournalResourcesLocation	@"Resources"
#define PDJournalDropBoxLocation	@"Journler Drop Box"

#define PDJournalImagesLoc			@"Images"
#define	PDAudioLoc					@"Audio Recordings"
#define PDVideoLoc					@"Video Recordings"

#define PDJournalBookmarksLoc		@"Bookmarks"
#define PDJournalWebArchivesLoc		@"WebArchives"
#define PDJournalPDFDocsLoc			@"PDFDocuments"

#define	PDJournalPasswordProtectedLoc @".journalProtected"
#define PDJournalWordListLoc		@"Auto-Correct Word List.csv"

//Deprecated
//#define		supportPath				@"/Library/Application Support/Journler/"

#define PDJournalIdentifier			@"JournalID"
#define	PDJournalVersion			@"Version"
#define	PDJournalBlogs				@"Blogs"
#define PDJournalTitle				@"Title"
#define PDJournalCategories			@"Categories"
#define PDJournalCollections		@"Collections"
#define PDJournalEncryptionState	@"PDJournalEncryptionState"
#define PDJournalEncrypted			@"PDJournalEncrypted"
#define PDJournalMainWindowState	@"PDJournalMainWindowState"
#define PDJournalProperShutDown		@"PDJournalProperShutDown"

#define JournalWillAddEntryNotification			@"JournalWillAddEntryNotification"
#define JournalDidAddEntryNotification			@"JournalDidAddEntryNotification"

#define JournalWillDeleteEntryNotification		@"JournalWillDeleteEntryNotification"
#define JournalDidDeleteEntryNotification		@"JournalDidDeleteEntryNotification"


#define JournalWillAddFolderNotification		@"JournalWillAddFolderNotification"
#define JournalDidAddFolderNotification			@"JournalDidAddFolderNotification"

#define JournalWillDeleteFolderNotification		@"JournalWillDeleteFolderNotification"
#define JournalDidDeleteFolderNotification		@"JournalDidDeleteFolderNotification"


#define JournalWillAddResourceNotificiation		@"JournalWillAddResourceNotificiation"
#define JournalDidAddResourceNotification		@"JournalDidAddResourceNotification"

#define JournalWillDeleteResourceNotificiation	@"JournalWillDeleteResourceNotificiation"
#define JournalDidDeleteResourceNotification	@"JournalDidDeleteResourceNotification"


#define JournalWillAddBlogNotification			@"JournalWillAddBlogNotification"
#define JournalDidAddBlogNotification			@"JournalDidAddBlogNotification"

#define JournalWillDeleteBlogNotification		@"JournalWillDeleteBlogNotification"
#define JournalDidDeleteBlogNotification		@"JournalDidDeleteBlogNotification"


#define JournalWillTrashEntryNotification		@"JournalWillTrashEntryNotification"
#define JournalDidTrashEntryNotification		@"JournalDidTrashEntryNotification"

#define JournalWillUntrashEntryNotification		@"JournalWillUntrashEntryNotification"
#define JournalDidUntrashEntryNotification		@"JournalDidUntrashEntryNotification"


typedef enum {
	PDEncryptionNone = 0,
	PDEncryptionJournal = 1,
	PDEncryptionEntry = 2
} JournalEncryptionOption;

typedef UInt32 EntrySaveOptions;
enum EntrySaveOperation {
	kEntrySaveIndexAndCollect = 0,
	kEntrySaveDoNotIndex = 1 << 1,
	kEntrySaveDoNotCollect = 1 << 2
};

typedef UInt32 JournalLoadFlag;
enum JournalLoadNotes {
	kJournalLoadedNormally = 0,
	kJournalUpgraded = 1 << 1,
	kJournalCrashed = 1 << 2,
	kJournalCouldNotLoad = 1 << 3,
	kJournalNoSearchIndex = 1 << 4,
	kJournalPathInitErrors = 1 << 5,
	kJournalWantsUpgrade = 1 << 6
};

typedef enum {
	PDJournalNoError = 0,
	PDNoJournalAtPath = 1 << 1,
	PDJournalFormatTooOld = 1 << 2,
	PDEncryptedAtUgrade = 1 << 3,
	PDUnreadableProperties = 1 << 4,
	PDJournalNoSearchIndexError = 1 << 5,
	PDJournalStoreAndPathFailure = 1 << 6,
	
	kJournalWants250Upgrade = 1 << 7,
	
} JournalLoadNotesDetails;

typedef enum {
	JournlerFoldersDirectory = 1,
	JournlerEntriesDirectory,
	JournlerBlogsDirectory,
	JournlerResourcesDirectory,
	JournlerDropBoxDirectory,
	JournlerPropertiesDocument,
	JournlerStoreDocument
} JournlerSupportPath;

@class JournlerEntry;
@class JournlerResource;
@class JournlerCollection;
@class BlogPref;

@class JournlerIndexServer;
@class JournlerSearchManager;

@interface JournlerJournal : NSObject
{
	NSMutableDictionary	*_properties;
	NSString *_password;
	
	// arrays stored the objects for the controllers
	NSMutableArray *_entries;
	NSMutableArray *_folders;
	NSMutableArray *_blogs;
	NSMutableArray *_resources;
	
	NSMutableArray *_rootFolders;
	
	// dictionaries store the objects for a quick lookup
	NSMutableDictionary	*_entriesDic;
	NSMutableDictionary	*_foldersDic;
	NSMutableDictionary *_blogsDic;
	NSMutableDictionary *_resourcesDic;
	
	NSMutableDictionary *_entryWikis;
	NSMutableSet *_entryTags;
	
	NSNumber *_dirty;
	
	// version 1.2 addition
	JournlerCollection	*_libraryCollection;
	JournlerCollection	*_trashCollection;
	
	// version 1.0.3 additions (collections and internal searching)
	JournlerSearchManager	*_searchManager;
	JournlerIndexServer		*_indexServer;
	
	// to keep track of our entries 
	// in the simplest way possible
	NSInteger lastTag;
	NSInteger lastFolderTag;
	NSInteger lastBlogTag;
	NSInteger lastResourceTag;
	
	//internal usage
	BOOL _loaded;
	NSInteger error;
	
	id _owner; // application owner for scripting
	
	EntrySaveOptions _saveEntryOptions;
	
	NSString *_journalPath;
	
	NSMutableArray *_initErrors;
	NSMutableString *_activity;
	
	// checks the entry content last accessed 
	// and releases attributed content that 
	// haven't been used for a while
	NSTimer *_contentMemoryManagerTimer;
	
	// would love to move this into the method that uses it
	NSInteger _menuRepresentationOptions;
}

+ (JournlerJournal*) sharedJournal;
+ (JournlerJournal*) defaultJournal:(NSError**)error; // I DON'T SEEM TO USE THIS METHOD
+ (NSString*) defaultJournalPath; // OR THIS METHOD?

//loading entries and topics into the model
- (JournalLoadFlag) loadFromPath:(NSString*)path error:(NSInteger*)err;
- (JournalLoadFlag) loadFromStore:(NSInteger*)err;
- (JournalLoadFlag) loadFromDirectoryIgnoringEntryFolders:(BOOL)ignore210Entries error:(NSInteger*)err;

#pragma mark -
#pragma mark entries

- (NSArray*) entries;
- (void) setEntries:(NSArray*)newEntries;

- (NSUInteger) countOfEntries;
- (id) objectInEntriesAtIndex:(NSUInteger)theIndex;
- (void) getEntries:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inEntriesAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromEntriesAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInEntriesAtIndex:(NSUInteger)theIndex withObject:(id)obj;

#pragma mark -
#pragma mark resources

- (NSArray*) resources;
- (void) setResources:(NSArray*)newResources;

- (NSUInteger) countOfResources;
- (id) objectInResourcesAtIndex:(NSUInteger)theIndex;
- (void) getResources:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inResourcesAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromResourcesAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInResourcesAtIndex:(NSUInteger)theIndex withObject:(id)obj;

#pragma mark -
#pragma mark folders

- (NSArray*) collections;
- (void) setCollections:(NSArray*)newCollections;

- (NSUInteger) countOfCollections;
- (id) objectInCollectionsAtIndex:(NSUInteger)theIndex;
- (void) getCollections:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inCollectionsAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromCollectionsAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInCollectionsAtIndex:(NSUInteger)theIndex withObject:(id)obj;

#pragma mark -
#pragma mark root folders

- (NSArray*) rootFolders;
- (void) setRootFolders:(NSArray*)anArray;

- (NSUInteger) countOfRootFolders;
- (id) objectInRootFoldersAtIndex:(NSUInteger)theIndex;
- (void) getRootFolders:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inRootFoldersAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromRootFoldersAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInRootFoldersAtIndex:(NSUInteger)theIndex withObject:(id)obj;

#pragma mark -

- (NSNumber*) version;
- (void) setVersion:(NSNumber*)newVersion;

- (NSNumber*) identifier;
- (void) setIdentifier:(NSNumber*)jid;

- (NSNumber*) shutDownProperly;
- (void) setShutDownProperly:(NSNumber*)aNumber;

- (NSNumber*) dirty;
- (void) setDirty:(NSNumber*)aNumber;

- (NSInteger) error;
- (void) setError:(NSInteger)err;

- (NSString*) title;
- (void) setTitle:(NSString*)newObject;

- (NSArray*) categories;
- (void) setCategories:(NSArray*)newObject;

- (NSArray*) blogs;
- (void) setBlogs:(NSArray*)newObject;

- (NSData*) tabState;
- (void) setTabState:(NSData*)data;

- (NSDictionary*) properties;
- (void) setProperties:(NSDictionary*)newObject;

- (NSString*) journalPath;
- (void) setJournalPath:(NSString*)newObject;

- (NSString*) activity;
- (void) setActivity:(NSString*)aString;

- (BOOL) isLoaded;
- (void) setLoaded:(BOOL)loaded;

- (EntrySaveOptions) saveEntryOptions;
- (void) setSaveEntryOptions:(EntrySaveOptions)options;

- (NSArray*) initErrors;

#pragma mark -

- (NSDictionary*) entriesDictionary;
- (NSDictionary*) collectionsDictionary;
- (NSDictionary*) blogsDictionary;
- (NSDictionary*) resourcesDictionary;
- (NSDictionary*) entryWikisDictionary;

- (NSSet*) entryTags;

- (JournlerSearchManager*) searchManager;
- (JournlerIndexServer*) indexServer;

#pragma mark -

- (id) objectForURIRepresentation:(NSURL*)aURL;

- (void) entry:(JournlerEntry*)anEntry didChangeTitle:(NSString*)oldTitle;
- (void) entry:(JournlerEntry*)anEntry didChangeTags:(NSArray*)oldTags;

- (JournlerEntry*) entryForTagID:(NSNumber*)tagNumber;
- (JournlerCollection*) collectionForID:(NSNumber*)idTag;

- (NSArray*) entriesForTagIDs:(NSArray*)tagIDs;
- (NSArray*) resourcesForTagIDs:(NSArray*)tagIDs;
- (NSArray*) collectionsForIDs:(NSArray*)tagIDs;

//return a new entry or topic tag number
- (NSInteger) newEntryTag;
- (NSInteger) newFolderTag;
- (NSInteger) newResourceTag;

// collections (v1.0.3)
- (void) updateIndexAndCollections:(id)object;

- (void) _updateIndex:(JournlerEntry*)entry;
- (void) _updateCollections:(JournlerEntry*)entry;

- (NSArray*) collectionsForTypeID:(NSInteger)type;

- (JournlerCollection*) libraryCollection;
- (JournlerCollection*) trashCollection;

// for entry editing, redating
- (void) addEntry:(JournlerEntry*)entry;
- (void) addCollection:(JournlerCollection*)collection;
- (JournlerResource*) addResource:(JournlerResource*)aResource;

- (JournlerEntry*) bestOwnerForResource:(JournlerResource*)aResource;

- (JournlerResource*) alreadyExistingResourceWithType:(JournlerResourceType)type 
		data:(id)anObject 
		operation:(NewResourceCommand)command;
		
- (BOOL) removeResources:(NSArray*)resourceArray 
		fromEntries:(NSArray*)entriesArray 
		errors:(NSArray**)errorsArray;

// a 1.15 addition - trashing
- (void) markEntryForTrash:(JournlerEntry*)entry;
- (void) unmarkEntryForTrash:(JournlerEntry*)entry;

#pragma mark 1.2 Changes
// 1.2 changes

- (JournlerCollection*) unarchiveCollectionAtPath:(NSString*)path;
- (JournlerResource*) unarchiveResourceAtPath:(NSString*)path;

- (NSString*) pathForSupportDocumentOrDirectory:(JournlerSupportPath)identifier;

- (BOOL) performOneTwoMaintenance;

- (BOOL) save:(NSError**)error;
- (BOOL) saveEntry:(JournlerEntry*)entry;
- (BOOL) saveResource:(JournlerResource*)aResource;

// collapse one of these methods into the other?
- (BOOL) saveCollection:(JournlerCollection*)aCollection;
- (BOOL) saveCollection:(JournlerCollection*)aCollection saveChildren:(BOOL)recursive;

// used by the folders controller -- collapse?
- (void) saveCollections:(BOOL)onlyDirty;

- (void) saveProperties;

- (BOOL) deleteEntry:(JournlerEntry*)anEntry;
- (BOOL) deleteResource:(JournlerResource*)aResource;
- (BOOL) deleteCollection:(JournlerCollection*)collection deleteChildren:(BOOL)children;

- (void) checkMemoryUse:(id)anObject;
- (void) _checkMemoryUse:(id)anObject;

- (void) checkForModifiedResources:(id)anObject;
- (void) _checkForModifiedResources:(id)anObject;

#pragma mark -
#pragma mark root folder utilities
// these had previously been covered by the rootCollection object

- (void) addRootFolder:(JournlerCollection*)subfolder atIndex:(NSUInteger)index;
- (void) moveRootFolder:(JournlerCollection *)aFolder toIndex:(NSUInteger)anIndex;
- (void) removeRootFolder:(JournlerCollection*)subfolder;

#pragma mark -

- (BOOL) flatMenuRepresentationForRootFolders:(NSMenu**)aMenu 
		target:(id)object 
		action:(SEL)aSelector 
		smallImages:(BOOL)useSmallImages 
		inset:(NSInteger)level;

- (NSMenu*) menuRepresentationForRootFolders:(id)target 
		action:(SEL)aSelector 
		smallImages:(BOOL)useSmallImages 
		includeEntries:(BOOL)wEntries;

#pragma mark -
#pragma mark Deprecated Methods

- (NSInteger) newBlogTag; //DEPRECATED
- (BOOL) saveBlog:(BlogPref*)aBlog; //DEPRECATED
- (BOOL) deleteBlog:(BlogPref*)aBlog; // DEPRECATED

- (BlogPref*) unarchiveBlogAtPath:(NSString*)path; // DEPRECATED

// is this method not used?
- (BOOL) hasChanges JOURNLER_DEPRECATED;

// blogs no longer supported
- (void) addBlog:(BlogPref*)aBlog JOURNLER_DEPRECATED;

// DEPRECATED
- (NSString*) password JOURNLER_DEPRECATED;
- (void) setPassword:(NSString*)encryptionPassword JOURNLER_DEPRECATED;

// used to read jentry files
- (JournlerEntry*) unpackageEntryAtPath:(NSString*)filepath JOURNLER_DEPRECATED;

@end

#pragma mark -

@interface JournlerJournal (ConsoleUtilities)

// console utilities
- (BOOL) resetSearchManager;
- (BOOL) resetEntryDateModified;
- (BOOL) resetSmartFolders;
- (BOOL) createResourcesForLinkedFiles;
- (BOOL) updateJournlerResourceTitles;
- (BOOL) resetResourceText;
- (BOOL) resetRelativePaths;

- (NSArray*) orphanedResources;
- (BOOL) deleteOrphanedResources:(NSArray*)theResources;

@end

#pragma mark -

@interface JournlerJournal (JournlerScripting)

- (id) owner;
- (void) setOwner:(id)owningObject;

@end

#pragma mark -

@interface NSObject (JournalSpellChecking)

- (NSInteger) spellDocumentTag;

@end
