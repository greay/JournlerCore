//
//  JournlerJournal.m
//  JournlerCore
//
//  Created by Philip Dow on xx.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//


#import <JournlerCore/JournlerJournal.h>
#import <JournlerCore/JournlerEntry.h>
#import <JournlerCore/JournlerCollection.h>
#import <JournlerCore/JournlerResource.h>
#import <JournlerCore/BlogPref.h>
#import <JournlerCore/JournlerSearchManager.h>
#import <JournlerCore/JournlerIndexServer.h>

#import <SproutedUtilities/SproutedUtilities.h>
#import <JournlerCore/NSURL+JournlerAdditions.h>

#import <JournlerCore/JournlerSingletons.h>
#import <JournlerCore/Definitions.h>

#define kJournlerLatestDataVersion 253

#warning everything is dirty too early!
#warning what about creating something like the NSEntityDescription for inserting new objects in the journal
	// it would automatically establish relationships
	// set the tag id
	// applescript container and so on.
	// I could remove the addEntry, addResource and addFolder methods

@implementation JournlerJournal

// ============================================================
// Birth and Death
// ============================================================

+ (JournlerJournal*) sharedJournal 
{
    static JournlerJournal *sharedJournal = nil;
    if (!sharedJournal) 
	{
        sharedJournal = [[JournlerJournal allocWithZone:NULL] init];
    }

    return sharedJournal;
}

+ (JournlerJournal*) defaultJournal:(NSError**)error
{
	NSInteger jError = 0;
	JournalLoadFlag loadResult;
	NSString *defaultPath = [JournlerJournal defaultJournalPath];
	
	// estalish the shared journal
	JournlerJournal *aJournal = [JournlerJournal sharedJournal];
	
	// and load the journal
	loadResult = [aJournal loadFromPath:defaultPath error:&jError];
	
	// do error checking and all that good stuff
	return aJournal;
}

+ (NSString*) defaultJournalPath
{
	NSDictionary *journlerDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.phildow.journler"];
	if ( journlerDefaults == nil )
		return nil;
	
	NSString *defaultPath = [[journlerDefaults objectForKey:@"Default Journal Location"] stringByStandardizingPath];
	return defaultPath;
}

- (id) init 
{
	// Designated initializer
	// - ensures that required variables are at least initialized
	
	if ( self = [super init] ) 
	{
		
		// v1.0.2 and v1.0.3 implementation
		_journalPath = [[NSString alloc] init];
		
		_properties = [[NSMutableDictionary alloc] init];
		
		_entries = [[NSMutableArray allocWithZone:[self zone]] init];
		_folders = [[NSMutableArray allocWithZone:[self zone]] init];
		_blogs = [[NSMutableArray allocWithZone:[self zone]] init];
		_resources = [[NSMutableArray alloc] init];
		
		_rootFolders = [[NSMutableArray alloc] init];

		
		// dictionaries for quick access
		_entriesDic = [[NSMutableDictionary allocWithZone:[self zone]] init];
		_foldersDic = [[NSMutableDictionary allocWithZone:[self zone]] init];
		_blogsDic = [[NSMutableDictionary allocWithZone:[self zone]] init];
		_resourcesDic = [[NSMutableDictionary alloc] init];
		
		_entryWikis = [[NSMutableDictionary alloc] init];
		_entryTags = [[NSMutableSet alloc] init];
		
		// the search manager belongs to the journal
		// the index server needs the search manager
		
		_searchManager = [[JournlerSearchManager alloc] initWithJournal:self];
		_indexServer = [[JournlerIndexServer alloc] initWithSearchManager:_searchManager];
		
		_saveEntryOptions = kEntrySaveIndexAndCollect;
		
		// by default no encryption
		_password = nil;
		
		lastTag	= 0;
		lastFolderTag = 0;
		lastBlogTag = 0;
		lastResourceTag = 0;

		error = 0;
		
		_initErrors = [[NSMutableArray alloc] init];
		_activity = [[NSMutableString alloc] init];
	
		_loaded = NO;
	}
	
	return self;
}

- (void) dealloc 
{
	[_entryWikis release], _entryWikis = nil;
	[_entryTags release], _entryTags = nil;
	
	// 1.0.2 changes ------------------
	[_journalPath release], _journalPath = nil;
	[_properties release], _properties = nil;
		
	// 1.0.3 changes
	[_entries release]; _entries = nil;
	[_folders release], _folders = nil;
	
	[_entriesDic release], _entriesDic = nil;
	[_foldersDic release], _foldersDic = nil;
	
	[_resources release], _resources = nil;
	[_resourcesDic release], _resourcesDic = nil;
	
	[_blogs release], _blogs = nil;
	[_blogsDic release], _blogsDic = nil;
	
	[_searchManager release], _searchManager = nil;
	[_indexServer release], _indexServer = nil;
	
	[_dirty release], _dirty = nil;
	[_initErrors release], _initErrors = nil;
	[_activity release], _activity = nil;
	
	[_contentMemoryManagerTimer invalidate];
	[_contentMemoryManagerTimer release], _contentMemoryManagerTimer = nil;
	
	// and deregister ourselves from the notification center
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

#pragma mark -

- (NSNumber*) dirty
{
	return _dirty;
}

- (void) setDirty:(NSNumber*)aNumber
{
	if ( ![_dirty isEqualToNumber:aNumber] )
	{
		[_dirty release];
		_dirty = [aNumber retain];
	}
}

- (NSNumber*) version 
{ 
	return [_properties objectForKey:PDJournalVersion]; 
}

- (void) setVersion:(NSNumber*)newVersion 
{
	[_properties setObject:(newVersion?newVersion:[NSNumber numberWithInt:kJournlerLatestDataVersion]) forKey:PDJournalVersion];
}

- (NSNumber*) shutDownProperly
{
	return [_properties objectForKey:PDJournalProperShutDown]; 
}	

- (void) setShutDownProperly:(NSNumber*)aNumber
{
	[_properties setObject:(aNumber?aNumber:[NSNumber numberWithBool:NO]) forKey:PDJournalProperShutDown];
}

- (NSNumber*) identifier 
{ 
	return [_properties objectForKey:PDJournalIdentifier]; 
}

- (void) setIdentifier:(NSNumber*)jid 
{
	[_properties setObject:(jid?jid:[NSNumber numberWithDouble:0]) forKey:PDJournalIdentifier];
}

- (NSData*) tabState
{
	return [_properties objectForKey:PDJournalMainWindowState];
}

- (void) setTabState:(NSData*)data
{
	[_properties setObject:( data ? data : [NSData data] ) forKey:PDJournalMainWindowState];
}

- (NSInteger) error { 
	return error; 
}

- (void) setError:(NSInteger)err {
	error = err;
}

#pragma mark -
#pragma mark entries

- (NSArray*) entries 
{
	return _entries; 
}

- (void) setEntries:(NSArray*)newEntries 
{
	if ( _entries != newEntries ) 
	{
		[_entries release];
		_entries = [newEntries mutableCopyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSUInteger)countOfEntries {
	return [_entries count];
}

- (id)objectInEntriesAtIndex:(NSUInteger)theIndex {
	return [_entries objectAtIndex:theIndex];
}

- (void)getEntries:(id *)objsPtr range:(NSRange)range {
	[_entries getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inEntriesAtIndex:(NSUInteger)theIndex {
	[_entries insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromEntriesAtIndex:(NSUInteger)theIndex {
	[_entries removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInEntriesAtIndex:(NSUInteger)theIndex withObject:(id)obj {
	[_entries replaceObjectAtIndex:theIndex withObject:obj];
}

#pragma mark -
#pragma mark resources

- (NSArray*) resources
{
	return _resources;
}

- (void) setResources:(NSArray*)newResources
{
	if ( _resources != newResources ) 
	{
		[_resources release];
		_resources = [newResources mutableCopyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSUInteger)countOfResources {
	return [_resources count];
}

- (id)objectInResourcesAtIndex:(NSUInteger)theIndex {
	return [_resources objectAtIndex:theIndex];
}

- (void)getResources:(id *)objsPtr range:(NSRange)range {
	[_resources getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inResourcesAtIndex:(NSUInteger)theIndex {
	[_resources insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromResourcesAtIndex:(NSUInteger)theIndex {
	[_resources removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInResourcesAtIndex:(NSUInteger)theIndex withObject:(id)obj {
	[_resources replaceObjectAtIndex:theIndex withObject:obj];
}

#pragma mark -
#pragma mark collections

- (NSArray*) collections 
{ 
	return _folders; 
}

- (void) setCollections:(NSArray*)newCollections 
{
	if ( _folders != newCollections ) 
	{
		[_folders release];
		_folders = [newCollections mutableCopyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSUInteger)countOfCollections {
	return [_folders count];
}

- (id)objectInCollectionsAtIndex:(NSUInteger)theIndex {
	return [_folders objectAtIndex:theIndex];
}

- (void)getCollections:(id *)objsPtr range:(NSRange)range {
	[_folders getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inCollectionsAtIndex:(NSUInteger)theIndex {
	[_folders insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromCollectionsAtIndex:(NSUInteger)theIndex {
	[_folders removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInCollectionsAtIndex:(NSUInteger)theIndex withObject:(id)obj {
	[_folders replaceObjectAtIndex:theIndex withObject:obj];
}

#pragma mark -
#pragma mark root folders

- (NSArray*) rootFolders {
	return _rootFolders;
}

- (void) setRootFolders:(NSArray*)anArray {
	if ( _rootFolders != anArray )
	{
		[_rootFolders release];
		_rootFolders = [anArray mutableCopyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSUInteger)countOfRootFolders {
	return [_rootFolders count];
}

- (id)objectInRootFoldersAtIndex:(NSUInteger)theIndex {
	return [_rootFolders objectAtIndex:theIndex];
}

- (void)getRootFolders:(id *)objsPtr range:(NSRange)range {
	[_rootFolders getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inRootFoldersAtIndex:(NSUInteger)theIndex {
	[_rootFolders insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromRootFoldersAtIndex:(NSUInteger)theIndex {
	[_rootFolders removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInRootFoldersAtIndex:(NSUInteger)theIndex withObject:(id)obj {
	[_rootFolders replaceObjectAtIndex:theIndex withObject:obj];
}

#pragma mark -
#pragma mark blogs
// second class citizens right now

- (NSArray*) blogs { 
	return _blogs; 
}

- (void) setBlogs:(NSArray*)newObject 
{
	if ( _blogs != newObject ) 
	{
		[_blogs release];
		_blogs = [newObject copyWithZone:[self zone]];
	}
}

#pragma mark -


- (NSString*) title 
{ 
	return [_properties objectForKey:PDJournalTitle]; 
}

- (void) setTitle:(NSString*)newObject 
{
	[_properties setObject:( newObject ? newObject : [NSString string] ) forKey:PDJournalTitle];
}

#pragma mark -



- (NSArray*) categories 
{ 
	return [_properties objectForKey:PDJournalCategories]; 
}

- (void) setCategories:(NSArray*)newObject 
{
	[_properties setObject:( newObject ? newObject : [NSArray array] ) forKey:PDJournalCategories];
}

#pragma mark -

- (NSDictionary*) properties 
{ 
	return _properties; 
}

- (void) setProperties:(NSDictionary*)newObject 
{
	if ( _properties != newObject ) 
	{
		[_properties release];
		_properties = [newObject mutableCopyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSString*) journalPath 
{ 
	return _journalPath; 
}

- (void) setJournalPath:(NSString*)newObject 
{
	if ( _journalPath != newObject ) 
	{
		[_journalPath release];
		_journalPath = [newObject copyWithZone:[self zone]];
	}
}

#pragma mark -

- (NSString*) activity
{
	return _activity;
}

- (void) setActivity:(NSString*)aString
{
	if ( _activity != aString )
	{
		[_activity release];
		_activity = [aString mutableCopyWithZone:[self zone]];
	}
}


- (EntrySaveOptions) saveEntryOptions {
	return _saveEntryOptions;
}

- (void) setSaveEntryOptions:(EntrySaveOptions)options {
	_saveEntryOptions = options;
}

#pragma mark -

- (BOOL) isLoaded 
{ 
	return _loaded; 
}

- (void) setLoaded:(BOOL)loaded
{
	_loaded = loaded;
}

#pragma mark -

- (NSArray*) initErrors
{
	return _initErrors;
}

- (JournlerSearchManager*)searchManager 
{ 
	return _searchManager; 
}

- (JournlerIndexServer*) indexServer
{
	return _indexServer;
}

#pragma mark -

- (id) objectForURIRepresentation:(NSURL*)aURL
{
	id object = nil;
	
	NSString *abs = [aURL absoluteString];
	NSString *tagID = [abs lastPathComponent];
	NSString *objectType = [[abs stringByDeletingLastPathComponent] lastPathComponent];
	
	if ( [objectType isEqualToString:@"entry"] )
		object = [_entriesDic objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	else if ( [objectType isEqualToString:@"reference"] )
		object = [_resourcesDic objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	else if ( [objectType isEqualToString:@"folder"] )
		object = [_foldersDic objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	else if ( [objectType isEqualToString:@"blog"] )
		object = [_blogsDic objectForKey:[NSNumber numberWithInt:[tagID intValue]]];
	
	return object;
}

- (JournlerEntry*) entryForTagID:(NSNumber*)tagNumber 
{
	return ( tagNumber != nil ? [_entriesDic objectForKey:tagNumber] : nil );
}

- (NSArray*) entriesForTagIDs:(NSArray*)tagIDs 
{	
	// utility for turning an array of entry ids into the entries themselves
	
	NSInteger i;
	NSMutableArray *theEntries = [[NSMutableArray alloc] initWithCapacity:[tagIDs count]];
	for ( i = 0; i < [tagIDs count]; i++ ) {
		id anEntry = [_entriesDic objectForKey:[tagIDs objectAtIndex:i]];
		if ( anEntry != nil ) [theEntries addObject:anEntry];
	}
	
	return [theEntries autorelease];
	
}

- (NSArray*) resourcesForTagIDs:(NSArray*)tagIDs
{
	// utility for turning an array of entry ids into the entries themselves
	
	NSInteger i;
	NSMutableArray *theResources = [[NSMutableArray alloc] initWithCapacity:[tagIDs count]];
	for ( i = 0; i < [tagIDs count]; i++ ) {
		id aResource = [_resourcesDic objectForKey:[tagIDs objectAtIndex:i]];
		if ( aResource != nil ) [theResources addObject:aResource];
	}
	
	return [theResources autorelease];
}

#pragma mark -

- (NSInteger) newEntryTag 
{
	return ++lastTag;
}

- (NSInteger) newFolderTag 
{
	return ++lastFolderTag;
}

- (NSInteger) newBlogTag 
{
	return ++lastBlogTag;
}

- (NSInteger) newResourceTag
{
	return ++lastResourceTag;
}

#pragma mark -
#pragma mark Loading 1.0.2 and 1.0.3 Style -> 1.2 style

- (JournalLoadFlag) loadFromPath:(NSString*)path error:(NSInteger*)err 
{	
	//
	// distinguish initialization and loading so that the journal can
	// be initialized without being loaded, and thus loaded after 
	// the password has gone through
	//
	// the loading code is a piece. 
	// upgrading should be completely distinguished from loading
	
	JournalLoadFlag loadResult = kJournalLoadedNormally;
	
	[_activity appendFormat:@"Loading journal from path %@\n", path];
	
	NSInteger i;
	error = 0;
	
	BOOL dir;
	
	*err = PDJournalNoError;
		
	// Complete failure if there is no directory at this path
	// ----------------------------------------------------------

	if ( ![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] || !dir ) {
		NSLog(@"%@ %s - critical Error : Unable to create journal : No journal at path %@", [self className], _cmd, path);
		[self setError:PDNoJournalAtPath];
		*err = PDNoJournalAtPath;
		return kJournalCouldNotLoad;
	}
	
	// go ahead and set our path if a directory does in fact exist here
	[self setJournalPath:path];
	
	// Check for the existense of the journal plist file
	// ----------------------------------------------------------

	if ( ![[NSFileManager defaultManager] fileExistsAtPath:[self pathForSupportDocumentOrDirectory:JournlerPropertiesDocument]] ) {
		
		NSLog(@"%@ %s - critical error: journal is in old format, requires 1.17 update", [self className], _cmd);
		[self setError:PDJournalFormatTooOld];
		*err = PDJournalFormatTooOld;
		return kJournalCouldNotLoad;
	}

	// Load the properties and check the version number
	// ----------------------------------------------------------

	[self setProperties:[NSDictionary dictionaryWithContentsOfFile:[self pathForSupportDocumentOrDirectory:JournlerPropertiesDocument]]];
	if ( [self title] == nil ) [self setTitle:[NSString string]];

	NSInteger versionNumber;
	id jVersionObj = [_properties objectForKey:PDJournalVersion];
	if ( [jVersionObj isKindOfClass:[NSString class]] ) {
		NSMutableString *journalVersion = [[_properties objectForKey:PDJournalVersion] mutableCopy];
		if ( !journalVersion ) {
			NSLog(@"%@ %s - critical Error : no journal version at %@", [self className], _cmd, 
					[self pathForSupportDocumentOrDirectory:JournlerPropertiesDocument]);
					
			[self setError:PDUnreadableProperties];
			*err = PDUnreadableProperties;
			return kJournalCouldNotLoad;
		}
		
		[journalVersion replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[journalVersion length])];
		versionNumber = [journalVersion intValue];
		
		[journalVersion release];
	}
	else
	{
		versionNumber = [jVersionObj intValue];
	}
	
	if ( versionNumber < 112 ) 
	{
		NSLog(@"%@ %s - critical error: journal is in old format, requires 1.17 update", [self className], _cmd);
		[self setError:PDJournalFormatTooOld];
		*err = PDJournalFormatTooOld;
		return kJournalCouldNotLoad;
	}
	
	else if ( versionNumber < 120 ) 
	{
		// the journal must be converted, but a simple enough process really		
		
		#warning must move the upgrade code out
		NSLog(@"%@ %s - critical error: journal is in old format, requires 120 (?) update", [self className], _cmd);
		[self setError:PDJournalFormatTooOld];
		*err = PDJournalFormatTooOld;
		return kJournalCouldNotLoad;
		
		/*
		JournalUpgradeController *upgrader = [[JournalUpgradeController alloc] init];
		[upgrader run117To210Upgrade:self];
		[upgrader release];
		
		loadResult |= kJournalUpgraded; 
		versionNumber = 250;
		*/
	}
	
	else if ( versionNumber < 250 )
	{
		loadResult |= kJournalWantsUpgrade;
		*err |= kJournalWants250Upgrade;
	}
	
	// actually load the journal
	// ----------------------------------------------------------
	BOOL loadSuccess = YES;
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:[self pathForSupportDocumentOrDirectory:JournlerStoreDocument]] )
	{
		if ( ![[self shutDownProperly] boolValue] )
		{
			// if the journal did not properly shut down, load from the directory
			NSInteger directoryError;
			JournalLoadFlag directoryLoadResult;
			
			loadResult |= kJournalCrashed;
			directoryLoadResult = [self loadFromDirectoryIgnoringEntryFolders:NO error:&directoryError];
			
			if ( directoryLoadResult != kJournalLoadedNormally )
				loadSuccess = NO;
		}
		else
		{
			// if journler did shut down successfully, first try to load from the store
			NSInteger storeError;
			JournalLoadFlag storeLoadResult = [self loadFromStore:&storeError];
			
			// attempt to load from the directory if a store load fails
			if ( storeLoadResult != kJournalLoadedNormally )
			{
				NSInteger directoryError;
				JournalLoadFlag directoryLoadResult = [self loadFromDirectoryIgnoringEntryFolders:NO error:&directoryError];
				
				if ( directoryLoadResult != kJournalLoadedNormally )
					loadSuccess = NO;
			}
		}
	}
	else
	{
		// load only those entries that are in the 200 format, in case the user runs a failed upgrade the second time
		NSInteger directoryError;
		JournalLoadFlag directoryLoadResult = [self loadFromDirectoryIgnoringEntryFolders:( versionNumber < 210 ) error:&directoryError];
		
		if ( directoryLoadResult != kJournalLoadedNormally )
			loadSuccess = NO;
	}
	
	if ( !loadSuccess )
	{
		//#warning indicate the error
		NSLog(@"%@ %s - unable to initialize journal from path %@", [self className], _cmd, path);
		*err = PDJournalStoreAndPathFailure;
		return kJournalCouldNotLoad;
	}
		
	// set every collections parent and children - after loading only
	for ( i = 0; i < [_folders count]; i++ ) 
	{
		JournlerCollection *aNode = [_folders objectAtIndex:i];
		
		// note a few special collections
		if ( [[aNode valueForKey:@"typeID"] intValue] == PDCollectionTypeIDTrash )
			_trashCollection = aNode;
			
		else if ( [[aNode valueForKey:@"typeID"] intValue] == PDCollectionTypeIDLibrary )
			_libraryCollection = aNode;

		// set the collection's relationship to other collections
		JournlerCollection *theParent = [self collectionForID:[aNode parentID]];
		[aNode setParent:( theParent != nil ? theParent : nil )];
		[aNode setChildren:[self collectionsForIDs:[aNode childrenIDs]]];
		
		// autosort the collections's children by their index value
		[aNode sortChildrenByIndex];
		
		// add the root collections to the root node
		if ( [aNode parent] == nil )
			[_rootFolders addObject:aNode];
	}
	
	// look for children attached to parents who have lost them and add them to the root folder
	for ( i = 0; i < [_folders count]; i++ ) 
	{
		JournlerCollection *aNode = [_folders objectAtIndex:i];
		JournlerCollection *theParent = [aNode parent];
		
		if ( theParent == nil )
			continue;
		
		NSArray *parentsChildren = [theParent children];
		if ( ![parentsChildren containsObject:aNode] )
		{
			[_activity appendFormat:@"%@ %s - Attaching lost folder to root list, title: %@, ID: %@\n", 
					[self className], 
					_cmd, 
					[aNode valueForKey:@"title"], 
					[aNode valueForKey:@"tagID"]];
					
			[_rootFolders addObject:aNode];
		}
	}
	
	// make sure we have a trash collection and library collection
	if ( _libraryCollection == nil ) 
	{
		// prepare the journal collection
		JournlerCollection *journal_collection;
		NSString *journal_collection_path = [[NSBundle mainBundle] pathForResource:@"JournalCollection" ofType:@"xml"];
		NSMutableDictionary *journal_collection_dic = [NSMutableDictionary dictionaryWithContentsOfFile:journal_collection_path];
	
		journal_collection = [[JournlerCollection alloc] initWithProperties:journal_collection_dic];
		if ( !journal_collection ) NSLog(@"%@ %s - could not create the journal collection", [self className], _cmd);
	
		// set the image on the journal dictionary
		[journal_collection determineIcon];
		
		// set the id
		[journal_collection setValue:[NSNumber numberWithInt:[self newFolderTag]] forKey:@"tagID"];
		
		// the position and parent
		[journal_collection setValue:[NSNumber numberWithInt:0] forKey:@"index"];
		[journal_collection setParentID:[NSNumber numberWithInt:-1]];
		[journal_collection setParent:nil];
		
		// add it and clean up
		[_rootFolders addObject:journal_collection];
		[_folders addObject:journal_collection];
		
		_libraryCollection = journal_collection;
		[self saveCollection:_libraryCollection];
		[journal_collection release];

	}
	
	if ( _trashCollection == nil ) 
	{
		// prepare the trash collection - collection tutorials
		JournlerCollection *trash_collection;
		NSString *trash_collection_path = [[NSBundle mainBundle] pathForResource:@"TrashCollection" ofType:@"xml"];
		NSMutableDictionary *trash_collection_dic = [NSMutableDictionary dictionaryWithContentsOfFile:trash_collection_path];
		
		trash_collection = [[JournlerCollection alloc] initWithProperties:trash_collection_dic];
		if ( !trash_collection ) NSLog(@"%@ %s - could not create the trash collection", [self className], _cmd);
		
		// set the image and title the tutorial dictionary
		[trash_collection determineIcon];
		[trash_collection setTitle:NSLocalizedString(@"collection trash title",@"")];
		
		// set the id
		[trash_collection setValue:[NSNumber numberWithInt:[self newFolderTag]] forKey:@"tagID"];
		
		// the position and parent
		[trash_collection setValue:[NSNumber numberWithInt:1] forKey:@"index"];
		[trash_collection setParentID:[NSNumber numberWithInt:-1]];
		[trash_collection setParent:nil];
		
		// add it and clean up
		[_rootFolders insertObject:trash_collection atIndex:1];
		[_folders addObject:trash_collection];
		
		_trashCollection = trash_collection;
		[self saveCollection:_trashCollection];
		[trash_collection release];
	}
	
	// sort the root node
	NSSortDescriptor *indexSort = [[[NSSortDescriptor alloc] initWithKey:PDCollectionIndex 
			ascending:YES 
			selector:@selector(compare:)] autorelease];
	[_rootFolders sortUsingDescriptors:[NSArray arrayWithObject:indexSort]];
	
	NSInteger foo;
	NSMutableArray *entriesTrashed = [NSMutableArray array];
	NSMutableArray *entriesNotTrashed = [NSMutableArray array];
	
	// trash/untrash entries and re-establish the relationship between the entry resources and the journal
	for ( foo = 0; foo < [_entries count]; foo++ ) {
		
		NSInteger g;
		JournlerEntry *anEntry = [_entries objectAtIndex:foo];
		
		// establish the entry -> resource relationships depending on version number
		
		if ( [[self version] intValue] < 250)
		{
			NSArray *entryResources = [anEntry valueForKey:@"resources"];
			[entryResources setValue:self forKey:@"journal"];
					
			[_resources addObjectsFromArray:entryResources];
			for ( g = 0; g < [entryResources count]; g++ )
			{
				[_resourcesDic setObject:[entryResources objectAtIndex:g] forKey:[[entryResources objectAtIndex:g] valueForKey:@"tagID"]];
				
				if ( [[[entryResources objectAtIndex:g] valueForKey:@"tagID"] intValue] > lastResourceTag )
					lastResourceTag = [[[entryResources objectAtIndex:g] valueForKey:@"tagID"] intValue];
			}
		}
		
		else
		{
			NSArray *theResourceIDs = [anEntry resourceIDs];
			NSArray *theResources = [self resourcesForTagIDs:theResourceIDs];
			
			JournlerResource *lastResourceSelection = nil;
			NSNumber *lastResourceSelectionID = [anEntry lastResourceSelectionID];
			if ( lastResourceSelectionID != nil ) lastResourceSelection = [_resourcesDic objectForKey:lastResourceSelectionID];
			
			//#ifdef __DEBUG__
			//NSLog(@"Entry %@ has Resources %@", [anEntry tagID], [theResourceIDs componentsJoinedByString:@","]);
			//#endif
			
			// estalish the entry -> resources relationship
			[anEntry setResources:theResources];
			
			// establish the entry -> selected resource relationship
			[anEntry setSelectedResource:lastResourceSelection];
			
			// nil out those relational load values to release them
			[anEntry setResourceIDs:nil];
			[anEntry setLastResourceSelectionID:nil];
		}
		
		// the entry belongs in the library or the trash
		if ( [[anEntry valueForKey:@"markedForTrash"] boolValue] )
			[entriesTrashed addObject:anEntry];
		else
			[entriesNotTrashed addObject:anEntry];
		
		// add the entry to the wiki dictionary
		NSString *wikiTitle = [anEntry wikiTitle];
		if ( wikiTitle != nil )
			[_entryWikis setValue:[anEntry URIRepresentation] forKey:wikiTitle];
	}
	
	// go through the resources and establish the resource -> entry relationships as well as the owner
	
	JournlerResource *aResource;
	NSEnumerator *resourceEnumerator = [_resources objectEnumerator];
	
	while ( aResource = [resourceEnumerator nextObject] )
	{
		// establish the resource -> entry relationship for each resource here
		NSNumber *owningEntryID = [aResource owningEntryID];
		NSArray *theEntryIDs = [aResource entryIDs];
		
		JournlerEntry *theOwningEntry = [_entriesDic objectForKey:owningEntryID];
		NSArray *allAssociatedEntries = [self entriesForTagIDs:theEntryIDs];
		
		#ifdef __DEBUG_
		NSLog(@"Resource %@ is owned by %@ has Entries %@", [aResource tagID], owningEntryID, [theEntryIDs componentsJoinedByString:@","]);
		#endif
		
		// establish the resource -> owning entry relationship
		[aResource setEntry:theOwningEntry];
		
		// establish the resource -> entries relationship
		[aResource setEntries:allAssociatedEntries];
		
		// nil out the relational load values
		[aResource setOwningEntryID:nil];
		[aResource setEntryIDs:nil];
		
		// once the relatinoships are established, make sure the resource does in fact have an owning entry
		if ( theOwningEntry == nil )
		{
			// this is a stray resource, associate it with a document, preferably one of the entries it already belongs to
			JournlerEntry *bestOwner = [self bestOwnerForResource:aResource];
			if ( bestOwner == nil )
			{
				// #warning attach stray resources to a dedicated entry
				// note the problem to the activity log
				[_activity appendFormat:@"** Permanently lost resource, cannot find any associated entries...\n\t-- Name: %@\n\t-- ID: %@\n", [aResource valueForKey:@"title"], [aResource valueForKey:@"tagID"]];
				if ( [aResource representsFile] ) [_activity appendFormat:@"\t-- Filename: %@\n",  [aResource filename]];
			}
			else
			{
				// re-establish the entry relationship - establish the entries relationship itself
				[aResource setEntry:bestOwner];
				
				// ensure the entry contains this resource, re-establishing if necessary
				[bestOwner addResource:aResource];
				
				// note the success to the activity log
				[_activity appendFormat:@"Successfully re-attached lost resource to new entry...\n\t-- Name: %@\n\t-- ID: %@\n\t-- New Parent Entry Name: %@\n\tNew Parent Entry ID: %@\n", [aResource valueForKey:@"title"], [aResource valueForKey:@"tagID"], [bestOwner valueForKey:@"title"], [bestOwner valueForKey:@"tagID"]];
				if ( [aResource representsFile] ) [_activity appendFormat:@"\t-- Filename: %@\n",  [aResource filename]];
			}
			
			// try bestOwnerForResource
			// if it returns a best owner, be sure to add it to the entry's genera resources array
			
			
		}

	}

	// establish the folder <-> entry relationships and other folder properties
	NSMutableArray *dynamicallyUpdatedSmartFolders = [NSMutableArray array];
	
	for ( i = 0; i < [_folders count]; i++ ) {
		
		JournlerCollection *aNode = [_folders objectAtIndex:i];
		
		// convert the entry ids into actual entries, all entries for library
		if ( [[aNode typeID] intValue] == PDCollectionTypeIDLibrary )
			[aNode setEntries:entriesNotTrashed];
			
		// a few entries for the trash
		else if ( [[aNode typeID] intValue] == PDCollectionTypeIDTrash )
			[aNode setEntries:entriesTrashed];
			
		// the rest of the entries in their respective folders, noting the folder as well
		else
		{
			NSArray *actualEntries = [self entriesForTagIDs:[aNode entryIDs]];
			JournlerEntry *anEntry;
			NSEnumerator *entryEnumerator = [actualEntries objectEnumerator];
			
			while ( anEntry = [entryEnumerator nextObject] )
			{
				NSMutableArray *entryFolders = [[[anEntry valueForKey:@"collections"] mutableCopyWithZone:[self zone]] autorelease];
				if ( entryFolders == nil )
					entryFolders = [NSMutableArray array];
				
				if ( [entryFolders indexOfObjectIdenticalTo:aNode] == NSNotFound )
				{
					[entryFolders addObject:aNode];
					[anEntry setValue:entryFolders forKey:@"collections"];
				}
			}
			
			[aNode setEntries:actualEntries];
		}
		
		// handle dyamically generated dates and note which folders have been changed
		if ( [aNode generateDynamicDatePredicates:NO] )
		{
			[dynamicallyUpdatedSmartFolders addObject:aNode];
		}
	}
	
	// re-evaluately the entries against any dynamically updated smart folders
	// this is done only after all of the smart folders have had their dynamic date conditions updated
	for ( i = 0; i < [dynamicallyUpdatedSmartFolders count]; i++ )
	{
		[[dynamicallyUpdatedSmartFolders objectAtIndex:i] invalidatePredicate:YES];
		[[dynamicallyUpdatedSmartFolders objectAtIndex:i] evaluateAndAct:[self entries] considerChildren:YES];
	}
	
	// derive all of the available tags
	[_entryTags addObjectsFromArray:[self valueForKeyPath:@"entries.@distinctUnionOfArrays.tags"]];
	//NSLog([_entryTags description]);

	// Upgrade the loaded journal to the 2.10 format, only after the load!
	
	if ( versionNumber < 210 )
	{
		
		/*
		JournalUpgradeController *upgrader = [[JournalUpgradeController alloc] init];
		[upgrader run200To210Upgrade:self];
		[upgrader release];
		
		loadResult |= kJournalUpgraded;
		*/
		
		#warning move the 210 upgrade code out
		NSLog(@"%@ %s - critical error: journal is in old format, requires 210 (?) update", [self className], _cmd);
		[self setError:PDJournalFormatTooOld];
		*err = PDJournalFormatTooOld;
		return kJournalCouldNotLoad;
	}

	
	// Prepare Journal Searching 
	// ----------------------------------------------------------

	if ( ![_searchManager loadIndexAtPath:[self journalPath]] )
	{
		NSLog(@"%@ %s - Unable to get or create the search indexes", [self className], _cmd);
		*err = PDJournalNoSearchIndexError;
		loadResult |= kJournalNoSearchIndex;
	}
	else 
	{
		//#warning compact the search index
		//[_searchManager compactIndex];
	}
	
	//
	// check for the existence of a journal id
	if ( ![self identifier] || [self identifier] == 0 )
		[self setIdentifier:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]]];
	
	// let all our object know that they have just been loaded, so they are not dirty
	NSNumber *notDirty = BooleanNumber(NO);
	
	[[self entries] setValue:notDirty forKey:@"dirty"];
	[[self collections] setValue:notDirty forKey:@"dirty"];
	[[self resources] setValue:notDirty forKey:@"dirty"];
	[self setValue:notDirty forKey:@"dirty"];
	
	_loaded = YES;
	
	// mark the journal as running for crash recovery
	[_properties setObject:[NSNumber numberWithBool:NO] forKey:PDJournalProperShutDown];
	[self saveProperties];
	
	// check for initialization errors and note them
	if ( [_initErrors count] != 0 )
		loadResult |= kJournalPathInitErrors;
	
	// log the activity
	[_activity appendString:@"Finished loading journal\n"];
	[self setActivity:_activity];
	
	// start up the memory manager
	_contentMemoryManagerTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:10*60] 
			interval:10*60 
			target:self 
			selector:@selector(checkMemoryUse:) 
			userInfo:nil 
			repeats:YES];
			
	[[NSRunLoop currentRunLoop] addTimer:_contentMemoryManagerTimer forMode:NSDefaultRunLoopMode];
	
	// let our caller know that an update was necessary
	return loadResult;
}

- (JournalLoadFlag) loadFromStore:(NSInteger*)err
{	
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	NSInteger i, c;
	JournalLoadFlag storeLoadFlag = kJournalLoadedNormally;
	
	NSArray *encodedEntries = nil, *encodedBlogs = nil, *encodedCollections = nil, *encodedResources = nil;
	NSMutableArray *theEntries, *theBlogs, *theCollections, *theResources;
	
	NSDictionary *store = [NSDictionary dictionaryWithContentsOfFile:[self pathForSupportDocumentOrDirectory:JournlerStoreDocument]];
	
	if ( store == nil )
	{
		NSLog(@"%@ %s - unable to initialize store dictionary from path %@", [self className], _cmd, 
				[self pathForSupportDocumentOrDirectory:JournlerStoreDocument]);
		return kJournalCouldNotLoad;
	}
	
	encodedEntries = [store valueForKey:@"Entries"];
	if ( encodedEntries == nil )
	{
		NSLog(@"%@ %s - store does not contain any entries", [self className], _cmd);
		return kJournalCouldNotLoad;
	}
	
	encodedBlogs = [store valueForKey:@"Blogs"];
	if ( encodedBlogs == nil )
	{
		NSLog(@"%@ %s - store does not contain any blogs", [self className], _cmd);
		return kJournalCouldNotLoad;
	}
	
	encodedCollections = [store valueForKey:@"Collections"];
	if ( encodedCollections == nil )
	{
		NSLog(@"%@ %s - store does not contain any collections", [self className], _cmd);
		return kJournalCouldNotLoad;
	}
	
	if ( [[self version] intValue] >= 250 )
	{
		encodedResources = [store valueForKey:@"Resources"];
		if ( encodedResources == nil )
		{
			NSLog(@"%@ %s - store does not contain any resources", [self className], _cmd);
			return kJournalCouldNotLoad;
		}
	}
	
	// DECODE THE ENTRIES
	c = 0;
	theEntries = [NSMutableArray arrayWithCapacity:[encodedEntries count]];
	for ( i = 0; i < [encodedEntries count]; i++ )
	{
		JournlerEntry *anEntry = nil;
		NSDictionary *entryDict = [encodedEntries objectAtIndex:i];
		NSData *rawData = [entryDict objectForKey:@"Data"]; 
		
		if ( rawData == nil )
		{
			NSLog(@"%@ %s - no data for entry %i in store", [self className], _cmd, i);
			continue;
		}
		
		@try
		{
			anEntry = [NSKeyedUnarchiver unarchiveObjectWithData:rawData];
		}
		@catch (NSException *localException)
		{
			anEntry = nil;
			NSLog(@"%@ %s - unable to unarchive entry %i in store, exception %@", [self className], _cmd, i, localException);
			[_initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:0], @"objectType",
					[NSString stringWithFormat:@"Entry %i in Store", i], @"errorString",
					localException, @"localException", nil]];
		}
		@finally
		{
			if ( anEntry == nil )
			{
				NSLog(@"%@ %s - error unarchiving entry %i in store", [self className], _cmd, i);
				continue;
			}
			else
			{
				[anEntry setScriptContainer:_owner];
				[anEntry setValue:self forKey:@"journal"];
				
				// add it to the dictionary
				[_entriesDic setObject:anEntry forKey:[anEntry tagID]];
				
				// add it to the temporary array
				[theEntries addObject:anEntry];
				
				// increment the tag and count
				c++;
				if ( lastTag < [[anEntry tagID] intValue] )
					lastTag = [[anEntry tagID] intValue];
			}
		}
	}
	
	//  set our entries array and numbers
	[self setEntries:theEntries];
	
	// DECODE THE FOLDERS
	c = 0;
	theCollections = [NSMutableArray arrayWithCapacity:[encodedCollections count]];
	for ( i = 0; i < [encodedCollections count]; i++ )
	{
		JournlerCollection *aCollection = nil;
		NSData *collectionData = [encodedCollections objectAtIndex:i];
		
		@try
		{
			aCollection = [NSKeyedUnarchiver unarchiveObjectWithData:collectionData];
		}
		@catch (NSException *localException)
		{
			aCollection = nil;
			NSLog(@"%@ %s - unable to unarchive folder %i in store, exception %@", [self className], _cmd, i, localException);
			[_initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:1], @"objectType",
					[NSString stringWithFormat:@"Folder %i in Store", i], @"errorString",
					localException, @"localException", nil]];
		}
		@finally
		{
			if ( aCollection == nil )
			{
				NSLog(@"%@ %s - error unarchiving collection %i in store", [self className], _cmd, i);
				continue;
			}
			else
			{
				[aCollection setScriptContainer:_owner];
				[aCollection setValue:self forKey:@"journal"];
				
				// add the collection to the collections dictionary
				[_foldersDic setObject:aCollection forKey:[aCollection tagID]];
				
				// add the collection to the temp collections array
				[theCollections addObject:aCollection];
					
				// update last tag and count
				c++;
				if ( lastFolderTag  < [[aCollection tagID] intValue] )
					lastFolderTag = [[aCollection tagID] intValue];
			}
		}
	}
	
	// set the collections array and number
	NSSortDescriptor *childSort = [[[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:@selector(compare:)] autorelease];
	[self setCollections:[theCollections sortedArrayUsingDescriptors:[NSArray arrayWithObject:childSort]]];
	
	// DECODE THE RESOURCES
	if ( [[self version] intValue] >= 250 )
	{
		c = 0;
		theResources = [NSMutableArray arrayWithCapacity:[encodedResources count]];
		for ( i = 0; i < [encodedResources count]; i++ )
		{
			JournlerResource *aResource = nil;
			NSData *resourceData = [encodedResources objectAtIndex:i];
			
			if ( resourceData == nil )
			{
				NSLog(@"%@ %s - no data for resource %i in store", [self className], _cmd, i);
				continue;
			}
			
			@try
			{
				aResource = [NSKeyedUnarchiver unarchiveObjectWithData:resourceData];
			}
			@catch (NSException *localException)
			{
				aResource = nil;
				NSLog(@"%@ %s - unable to unarchive resource %i in store, exception %@", [self className], _cmd, i, localException);
				[_initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						[NSNumber numberWithInt:3], @"objectType",
						[NSString stringWithFormat:@"Resource %i in Store", i], @"errorString",
						localException, @"localException", nil]];
			}
			@finally
			{
				if ( aResource == nil )
				{
					NSLog(@"%@ %s - error unarchiving resource %i in store", [self className], _cmd, i);
					continue;
				}
				else
				{
					[aResource setScriptContainer:_owner];
					[aResource setValue:self forKey:@"journal"];
					
					// add it to the dictionary
					[_resourcesDic setObject:aResource forKey:[aResource tagID]];
					
					// add it to the temporary array
					[theResources addObject:aResource];
					
					// increment the tag and count
					c++;
					if ( lastResourceTag < [[aResource tagID] intValue] )
						lastResourceTag = [[aResource tagID] intValue];
				}
			}
		}
		
		[self setResources:theResources];
	}
	
	// DECODE THE BLOGS
	c = 0;
	theBlogs = [NSMutableArray arrayWithCapacity:[encodedBlogs count]];
	for ( i = 0; i < [encodedBlogs count]; i++ )
	{
		BlogPref *aBlog = nil;
		NSData *blogData = [encodedBlogs objectAtIndex:i];
		
		@try
		{
			aBlog = [NSKeyedUnarchiver unarchiveObjectWithData:blogData];
		}
		@catch (NSException *localException)
		{
			aBlog = nil;
			NSLog(@"%@ %s - unable to unarchive blog %i in store, exception %@", [self className], _cmd, i, localException);
			[_initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:2], @"objectType",
					[NSString stringWithFormat:@"Blog %i in Store", i], @"errorString",
					localException, @"localException", nil]];
		}
		@finally
		{
			if ( aBlog == nil )
			{
				NSLog(@"%@ %s - error unarchiving blog %i in store", [self className], _cmd, i);
				continue;
			}
			else
			{
				//[aBlog setMyContainer:_owner];
				//[aBlog setValue:self forKey:@"theJournal"];
				[aBlog setValue:self forKey:@"journal"];
				
				// load the password for the blog from the keychain
				NSString *keychainUserName = [NSString stringWithFormat:@"%@-%@-%@", [aBlog blogType], [aBlog name], [aBlog login]];
			
				if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" 
						withItemKind:@"BlogPassword" 
						forUsername:keychainUserName] ) 
				{
					//set the password
					NSString *blog_password = [AGKeychain getPasswordFromKeychainItem:@"NameJournlerKey" 
							withItemKind:@"BlogPassword" 
							forUsername:keychainUserName];
							
					[aBlog setPassword:blog_password];
				}
				
				// the temp array
				[theBlogs addObject:aBlog];
				
				// the dictionary
				[_blogsDic setObject:aBlog forKey:[aBlog tagID]];
				
				// last count
				c++;
				if ( lastBlogTag < [[aBlog valueForKey:@"tagID"] intValue] )
					lastBlogTag = [[aBlog valueForKey:@"tagID"] intValue];	
			}
		}
	}
	
	// set the blogs array
	[self setBlogs:theBlogs];
	
	
	return storeLoadFlag;
}

- (JournalLoadFlag) loadFromDirectoryIgnoringEntryFolders:(BOOL)ignore210Entries error:(NSInteger*)err
{
		
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	NSInteger c;
	JournalLoadFlag directoryLoadFlag = kJournalLoadedNormally;
	
	NSString *pname;
	NSMutableArray *tempEntries = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *tempCollections = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *tempBlogs = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *tempResources = [[[NSMutableArray alloc] init] autorelease];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSEnumerator *contentsEnumerator;
	
	// LOAD THE BLOGS
	contentsEnumerator = [[fm directoryContentsAtPath:[self pathForSupportDocumentOrDirectory:JournlerBlogsDirectory]] objectEnumerator];

	c = 0;
	while ( pname = [contentsEnumerator nextObject] ) 
	{
		if ( [[pname pathExtension] isEqualToString:@"jblog"] ) 
		{
			BlogPref *aBlog = [self unarchiveBlogAtPath:[[self pathForSupportDocumentOrDirectory:JournlerBlogsDirectory] 
					stringByAppendingPathComponent:pname]];
			if ( aBlog != nil ) 
			{
				
				// scriptability
				//[aBlog setMyContainer:_owner];
				
				//[aBlog setValue:self forKey:@"theJournal"];
				[aBlog setValue:self forKey:@"journal"];
				
				// load the password for the blog from the keychain
				NSString *keychainUserName = [NSString stringWithFormat:@"%@-%@-%@", [aBlog blogType], [aBlog name], [aBlog login]];
			
				if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" 
						withItemKind:@"BlogPassword" 
						forUsername:keychainUserName] ) 
				{
					//set the password
					NSString *blog_password = [AGKeychain getPasswordFromKeychainItem:@"NameJournlerKey" 
							withItemKind:@"BlogPassword" 
							forUsername:keychainUserName];
							
					[aBlog setPassword:blog_password];
				}
				
				// the temp array
				[tempBlogs addObject:aBlog];
				
				// the dictionary
				[_blogsDic setObject:aBlog forKey:[aBlog tagID]];
				
				// last count
				if ( lastBlogTag < [[aBlog valueForKey:@"tagID"] intValue] )
					lastBlogTag = [[aBlog valueForKey:@"tagID"] intValue];
				
				c++;
				
			}
			else 
			{
				NSLog(@"%@ %s - Unable to read blog at path %@", [self className], _cmd, 
						[[self pathForSupportDocumentOrDirectory:JournlerBlogsDirectory] 
							stringByAppendingPathComponent:pname]);
			}
		}
	}
	
	[self setBlogs:tempBlogs];
	
	// LOAD THE ENTRIES
	contentsEnumerator = [[fm directoryContentsAtPath:[self pathForSupportDocumentOrDirectory:JournlerEntriesDirectory]] objectEnumerator];
	
	c = 0;
	while ( pname = [contentsEnumerator nextObject] ) 
	{
		if ([[pname pathExtension] isEqualToString:@"jentry"]) 
		{
			// load an entry in the 2.0 data format
			JournlerEntry *readEntry = [self unpackageEntryAtPath:[[self pathForSupportDocumentOrDirectory:JournlerEntriesDirectory] stringByAppendingPathComponent:pname]];
			if ( readEntry != nil) 
			{
				// Scriptability and journal relationship
				[readEntry setScriptContainer:_owner];
				[readEntry setValue:self forKey:@"journal"];

				// add it to the temp array
				[tempEntries addObject:readEntry];

				// add it to the dictionary
				[_entriesDic setObject:readEntry forKey:[readEntry tagID]];

				// increment the tag and count
				if ( lastTag < [[readEntry tagID] intValue] )
				lastTag = [[readEntry tagID] intValue];

				c++;
			}
			else 
			{
				NSLog(@"%@ %s - Unable to load entry at path %@", [self className], _cmd, [[self pathForSupportDocumentOrDirectory:JournlerEntriesDirectory] stringByAppendingPathComponent:pname]);
			}
		}
		
		else if ( ignore210Entries == NO && [pname rangeOfString:@"Entry"].location != NSNotFound )
		{
			// load an entry in the 2.1 format
			
			JournlerEntry *readEntry = nil;
			
			NSString *propertiesPath;
			NSArray *propertiesPossibilities = [[fm directoryContentsAtPath:[[self pathForSupportDocumentOrDirectory:JournlerEntriesDirectory] 
					stringByAppendingPathComponent:pname]] 
					pathsMatchingExtensions:[NSArray arrayWithObject:@"jobj"]];
					
			if ( [propertiesPossibilities count] == 1 )
				propertiesPath = [[[self pathForSupportDocumentOrDirectory:JournlerEntriesDirectory] 
						stringByAppendingPathComponent:pname] 
						stringByAppendingPathComponent:[propertiesPossibilities objectAtIndex:0]];
			else
				propertiesPath = [[[self pathForSupportDocumentOrDirectory:JournlerEntriesDirectory] 
						stringByAppendingPathComponent:pname] 
						stringByAppendingPathComponent:PDEntryPackageEntryContents];
			
			@try
			{
				readEntry = [NSKeyedUnarchiver unarchiveObjectWithFile:propertiesPath];
			}
			@catch (NSException *localException)
			{
				readEntry = nil;
				NSLog(@"%@ %s - unable to unarchive entry at path %@, exception %@", [self className], _cmd, 
						[[self pathForSupportDocumentOrDirectory:JournlerEntriesDirectory] 
						stringByAppendingPathComponent:pname], localException);
				
				[_initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						[NSNumber numberWithInt:0], @"objectType",
						[[self pathForSupportDocumentOrDirectory:JournlerEntriesDirectory] 
								stringByAppendingPathComponent:pname], @"errorString",
						localException, @"localException", nil]];
			}
			@finally
			{
				if ( readEntry != nil) 
				{
					// Scriptability and journal relationship
					[readEntry setScriptContainer:_owner];
					[readEntry setValue:self forKey:@"journal"];

					// add it to the temp array
					[tempEntries addObject:readEntry];

					// add it to the dictionary
					[_entriesDic setObject:readEntry forKey:[readEntry tagID]];

					// increment the tag and count
					if ( lastTag < [[readEntry tagID] intValue] )
					lastTag = [[readEntry tagID] intValue];

					c++;
				}
				else 
				{
					NSLog(@"%@ %s - Unable to load entry at path %@", [self className], _cmd, 
							[[self pathForSupportDocumentOrDirectory:JournlerEntriesDirectory] 
								stringByAppendingPathComponent:pname]);
					readEntry = nil;
				}
			}
		}
	}

	//  set our entries array and numbers
	[self setEntries:tempEntries];
	
	
	// handle collections for 1.2 - the root node
	// ----------------------------------------------------------	
	
	
	
	contentsEnumerator = [[fm directoryContentsAtPath:[self pathForSupportDocumentOrDirectory:JournlerFoldersDirectory]] objectEnumerator];
	
	c = 0;
	while ( pname = [contentsEnumerator nextObject] ) 
	{
		if ([[pname pathExtension] isEqualToString:@"jcol"]) 
		{
			JournlerCollection *aNode = (JournlerCollection*)[self unarchiveCollectionAtPath:
					[[self pathForSupportDocumentOrDirectory:JournlerFoldersDirectory] 
					stringByAppendingPathComponent:pname]];
					
			if ( aNode != nil ) 
			{
				// Scriptability and relationship to journal
				[aNode setScriptContainer:_owner];
				[aNode setValue:self forKey:@"journal"];
				
				// add the collection to the temp collections array
				[tempCollections addObject:aNode];
				
				// add the collection to the collections dictionary
				[_foldersDic setObject:aNode forKey:[aNode tagID]];
					
				// update last tag and count
				if ( lastFolderTag  < [[aNode tagID] intValue] )
					lastFolderTag = [[aNode tagID] intValue];

				c++;
			}
			else 
			{
				NSLog(@"%@ %s - Unable to load collection at path %@", [self className], _cmd, 
						[[self pathForSupportDocumentOrDirectory:JournlerFoldersDirectory] 
							stringByAppendingPathComponent:pname]);
			}
		}
	}
	
	// set the collections array and number
	NSSortDescriptor *childSort = [[[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES selector:@selector(compare:)] autorelease];
	[self setCollections:[tempCollections sortedArrayUsingDescriptors:[NSArray arrayWithObject:childSort]]];
	
	
	// LOAD THE RESOURCES
	if ( [[self version] intValue] >= 250 )
	{
		contentsEnumerator = [[fm directoryContentsAtPath:[self pathForSupportDocumentOrDirectory:JournlerResourcesDirectory]] objectEnumerator];
	
		c = 0;
		while ( pname = [contentsEnumerator nextObject] ) 
		{
			if ([[pname pathExtension] isEqualToString:@"jresource"]) 
			{
				JournlerResource *aResource = (JournlerResource*)[self unarchiveResourceAtPath:
				[[self pathForSupportDocumentOrDirectory:JournlerResourcesDirectory] stringByAppendingPathComponent:pname]];
				
				if ( aResource != nil ) 
				{
					// Scriptability and relationship to journal
					[aResource setScriptContainer:_owner];
					[aResource setValue:self forKey:@"journal"];
					
					// add the resource to the temp resources array
					[tempResources addObject:aResource];
					
					// add the resource to the resources dictionary
					[_resourcesDic setObject:aResource forKey:[aResource tagID]];
						
					// update last tag and count
					if ( lastResourceTag  < [[aResource tagID] intValue] )
						lastResourceTag = [[aResource tagID] intValue];

					c++;
				}
				else 
				{
					NSLog(@"%@ %s - Unable to load resource at path %@", [self className], _cmd, 
							[[self pathForSupportDocumentOrDirectory:JournlerResourcesDirectory] stringByAppendingPathComponent:pname]);
				}
			}
		}
		
		// set the resources
		[self setResources:tempResources];

	}
	
	
	return directoryLoadFlag;
}

#pragma mark -

- (void) entry:(JournlerEntry*)anEntry didChangeTitle:(NSString*)oldTitle
{
	// #warning if an entry takes on the name of another entry while the user is changing the title...
	
	// remove the old wiki title
	[_entryWikis removeObjectForKey:oldTitle];
	
	// get the new title
	NSString *newWikiTitle = [anEntry wikiTitle];
	
	if ( newWikiTitle != nil )
	{
		[_entryWikis setValue:[anEntry URIRepresentation] forKey:newWikiTitle];
		
		// don't mark the wiki title as needing spell correction
		if ( [[NSApp delegate] respondsToSelector:@selector(spellDocumentTag)] )
			[[NSSpellChecker sharedSpellChecker] ignoreWord:newWikiTitle inSpellDocumentWithTag:[[NSApp delegate] spellDocumentTag]];
	}
	
	// check all journler object resources and change their titles if necessary
	//NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %i AND uriString MATCHES %@", kResourceTypeJournlerObject, [anEntry URIRepresentationAsString]];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %i AND uriString == %@", kResourceTypeJournlerObject, [anEntry URIRepresentationAsString]];
	NSArray *filteredArray = [[self resources] filteredArrayUsingPredicate:predicate];
	
	if ( [filteredArray count] > 0 )
	{
		#ifdef __DEBUG__
		NSLog(@"%@ %s - updating the title on %i resources", [self className], _cmd, [filteredArray count]);
		#endif
		
		JournlerResource *aResources;
		NSEnumerator *enumerator = [filteredArray objectEnumerator];
		
		while ( aResources = [enumerator nextObject] )
			[aResources setValue:[anEntry valueForKey:@"title"] forKey:@"title"];
	}
}

- (void) entry:(JournlerEntry*)anEntry didChangeTags:(NSArray*)oldTags
{
	// dif the tags to discover which were removed and which were added
	// added tags may be immediately added to the set
	// for each removed tag, find out if there are still entries with that particular tag, if not, remove the tag from the set
	
	NSSet *currentTags = [NSSet setWithArray:[anEntry valueForKey:@"tags"]];
	NSSet *previousTags = [NSSet setWithArray:oldTags];
	
	NSMutableSet *addedItems = [NSMutableSet setWithSet:currentTags];
	NSMutableSet *removedItems = [NSMutableSet setWithSet:previousTags];
	
	[addedItems minusSet:previousTags];
	[removedItems minusSet:currentTags];
	
	[_entryTags unionSet:addedItems];
	
	NSString *aTag;
	NSEnumerator *enumerator = [removedItems objectEnumerator];
	
	while ( aTag = [[enumerator nextObject] lowercaseString] )
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ in tags.lowercaseString AND markedForTrash == NO",aTag];
		if ( [[[self entries] filteredArrayUsingPredicate:predicate] count] == 0 )
			[_entryTags removeObject:aTag];
	}
	
	//NSLog([_entryTags description]);
}

#pragma mark -

- (void) saveCollections:(BOOL)onlyDirty
{
	JournlerCollection *aFolder;
	NSEnumerator *enumerator = [[self collections] objectEnumerator];
	
	while ( aFolder = [enumerator nextObject] )
	{
		if ( [[aFolder dirty] boolValue] == YES )
			[self saveCollection:aFolder];
	}
}

- (void) saveProperties 
{		
	// write and log any errors
	if ( ![_properties writeToFile:[self pathForSupportDocumentOrDirectory:JournlerPropertiesDocument] atomically:YES] )
		NSLog(@"%@ %s - Unable to write journal properties to path %@", [self className], _cmd, 
				[self pathForSupportDocumentOrDirectory:JournlerPropertiesDocument]);
}

#pragma mark -

- (void) addBlog:(BlogPref*)aBlog 
{	
	// don't add the blog if we already have it
	if ( [_blogs indexOfObjectIdenticalTo:aBlog] != NSNotFound ) return;
	
	// make sure the blog has an approrpiate id
	if ( [[aBlog valueForKey:@"tagID"] intValue] == -1 ) 
		[aBlog setValue:[NSNumber numberWithInt:[self newBlogTag]] forKey:@"tagID"];
	
	// set its container
	//[aBlog setMyContainer:_owner];
	
	//[aBlog setValue:self forKey:@"theJournal"];
	[aBlog setValue:self forKey:@"journal"];
	
	// add the necessary keychain informaiton
	
	// add the blog to the array
	NSMutableArray *temp = [[self blogs] mutableCopyWithZone:[self zone]];
	
	[temp addObject:aBlog];
	[self setBlogs:temp];
	
	[temp release];
	
	// update the dictionary
	[_blogsDic setObject:aBlog forKey:[aBlog tagID]];
	
}

#pragma mark -

- (void) updateIndexAndCollections:(id)object 
{	
	//
	// and entry is still searchable if it is marked for deletion
	// do not update the collections with this entry if it is marked for delete
	
	if ( [object isKindOfClass:[JournlerEntry class]] ) 
	{
		//
		// a single entry, act accordingly
		
		[self _updateIndex:object];
		[self _updateCollections:object];
	
	}
	else if ( [object isKindOfClass:[NSArray class]] )  
	{
		//
		// an array of entries, act accordingly
		NSInteger i;
		for ( i = 0; i < [object count]; i++ ) {
			[self _updateIndex:[object objectAtIndex:i]];
			[self _updateCollections:[object objectAtIndex:i]];
		}
		
	}
}

- (void) _updateIndex:(JournlerEntry*)entry 
{
	// do not index entries that are marked for the trash
	if ( [[entry valueForKey:@"markedForTrash"] boolValue] )
		return;
		
	[_searchManager indexEntry:entry];	
}

- (void) _updateCollections:(JournlerEntry*)entry 
{	
	// do not update the collections with the entry if it is marked for trash
	if ( [[entry valueForKey:@"markedForTrash"] boolValue] )
		return;
	
	[_libraryCollection addEntry:entry];
	[[self collections] makeObjectsPerformSelector:@selector(evaluateAndAct:) withObject:entry];
}

#pragma mark -

- (NSArray*) collectionsForTypeID:(NSInteger)type 
{	
	NSInteger i;
	NSArray *collections = [_foldersDic allValues];
	NSMutableArray *returnArray = [[NSMutableArray alloc] initWithCapacity:[collections count]];
	
	for ( i = 0; i < [collections count]; i++ ) {
		
		if ( [[(JournlerCollection*)[collections objectAtIndex:i] valueForKey:@"typeID"] intValue] == type )
			[returnArray addObject:[collections objectAtIndex:i]];
		
	}
	
	return [returnArray autorelease];
}

- (JournlerCollection*) libraryCollection 
{
	return _libraryCollection;
}

- (JournlerCollection*) trashCollection 
{
	return _trashCollection;
}


// a 1.15 addition - trashing
- (void) markEntryForTrash:(JournlerEntry*)entry 
{
	
	if ( entry == nil )
		return;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillTrashEntryNotification object:self 
	userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"]];
	
	[entry retain];
	
	// mark it for trashing
	[entry setValue:BooleanNumber(YES) forKey:@"markedForTrash"];
	
	// remove it from every collection but the trash, making sure it is in the trash
	[[self collections] makeObjectsPerformSelector:@selector(removeEntry:) withObject:entry];
	[_trashCollection addEntry:entry];
	
	// entries marked for trash should not be searched
	[_searchManager removeEntry:entry];
	
	// write it out
	[self saveEntry:entry];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidTrashEntryNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"]];
	
	[entry release];
}

#pragma mark -
#pragma mark Root Folders Menu Representation

- (BOOL) flatMenuRepresentationForRootFolders:(NSMenu**)aMenu 
		target:(id)object 
		action:(SEL)aSelector 
		smallImages:(BOOL)useSmallImages 
		inset:(NSInteger)level 
{
	// this method is identifical to the one in JournlerCollection
	// except it targets the root folders here instead of any children
	
	NSMenu *menu = *aMenu;
	NSArray *theChildren = [self rootFolders];
	
	NSInteger i;
	for ( i = 0; i < [theChildren count]; i++ ) 
	{
		JournlerCollection *aChild = [theChildren objectAtIndex:i];
		NSString *childTitle = [aChild title];
		if ( childTitle == nil ) childTitle = [NSString string];
		
		// add each child to the menu, submenus if necessary
		NSMenuItem *item = [[[NSMenuItem alloc] 
				initWithTitle:childTitle
				action:aSelector 
				keyEquivalent:@""] autorelease];
		
		NSImage *itemImage;
		
		if ( useSmallImages ) 
			itemImage = [[aChild valueForKey:@"icon"] imageWithWidth:18 height:18 inset:0];
		else
			itemImage = [[aChild valueForKey:@"icon"] imageWithWidth:32 height:32 inset:0];
		
		[item setTarget:object];
		[item setTag:[[aChild  valueForKey:@"tagID"] intValue]];
		[item setImage:itemImage];
		[item setRepresentedObject:aChild];
		[item setIndentationLevel:level];
		
		[menu addItem:item];
		
		if ( [[theChildren objectAtIndex:i] countOfChildren] != 0 ) 
		{
			[aChild flatMenuRepresentation:&menu 
					target:object 
					action:aSelector 
					smallImages:useSmallImages 
					inset:level+1];
		}
	}
	
	return YES;
}

- (NSMenu*) menuRepresentationForRootFolders:(id)target 
		action:(SEL)aSelector 
		smallImages:(BOOL)useSmallImages 
		includeEntries:(BOOL)wEntries
{
	// noticing that with this new delegate format 
	// it takes a good bit longer for the program 
	// to quit after the menu has once been built
	
	// build the top level menu using the delegate methods
	// but then each submenu is built immediately
	
	// note the options
	_menuRepresentationOptions = kJournlerFolderMenuDefaultSettings;
	if ( wEntries ) _menuRepresentationOptions |= kJournlerFolderMenuIncludesEntries;
	if ( useSmallImages == NO ) _menuRepresentationOptions |= kJournlerFolderMenuUseLargeImages;
	
	// build the menu dynamically
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	[menu setDelegate:self];
	return menu;
}

- (BOOL)menu:(NSMenu *)menu 
		updateItem:(NSMenuItem *)item 
		atIndex:(NSInteger)index 
		shouldCancel:(BOOL)shouldCancel
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// get the count of the items in our children and entries arrays
	NSInteger childCount = [[self rootFolders] count];
	NSInteger totalCount = childCount;
	NSInteger actualIndex = index;
	
	// get my menu item - it holds the target and action
	NSMenuItem *superItem = [[menu supermenu] itemAtIndex:[[menu supermenu] indexOfItemWithSubmenu:menu]];
	
	NSArray *theChildren = [self rootFolders];
	JournlerCollection *aChild = [theChildren objectAtIndex:actualIndex];
		
	NSImage *itemImage = nil;
	if ( _menuRepresentationOptions & kJournlerFolderMenuUseLargeImages )
		itemImage = [[aChild valueForKey:@"icon"] imageWithWidth:32 height:32 inset:0];
	else
		itemImage = [[aChild valueForKey:@"icon"] imageWithWidth:18 height:18 inset:0];
			
	[item setTitle:[aChild title]];
	[item setTag:[[aChild valueForKey:@"tagID"] intValue]];
	[item setImage:itemImage];
	[item setRepresentedObject:aChild];
	
	[item setTarget:[superItem target]];
	[item setAction:[superItem action]];
	
	// do the same for the submenus, which just esatablishes the delegate
	if ( [aChild countOfChildren] != 0 
			|| ( ( _menuRepresentationOptions & kJournlerFolderMenuIncludesEntries ) 
				&& [[aChild entries] count] != 0 ) )
		[item setSubmenu:[aChild undelegatedMenuRepresentation:[superItem target] 
				action:[superItem action] 
				smallImages:!( _menuRepresentationOptions & kJournlerFolderMenuUseLargeImages ) 
				includeEntries:( _menuRepresentationOptions & kJournlerFolderMenuIncludesEntries )]];
			
	[pool release];

	return ( index < totalCount );
}

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
	NSInteger childCount = [[self rootFolders] count];
	return childCount;
}

#pragma mark -

- (void) unmarkEntryForTrash:(JournlerEntry*)entry {
	
	if ( entry == nil )
		return;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillUntrashEntryNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"]];
	
	[entry retain];
	
	// if the entry is marked for trash, unmark for trash
	[entry setValue:BooleanNumber(NO) forKey:@"markedForTrash"];
	
	// remove the entry from the trash
	[_trashCollection removeEntry:entry];
		
	// add the entry back to the journal and save
	[self addEntry:entry];
	[self saveEntry:entry];
		
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidUntrashEntryNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"]];
		
	[entry release];
	
}

#pragma mark -
#pragma mark Deprecated Methods

// DEPRECATED
- (NSString*) password 
{ 
	return _password; 
}

- (void) setPassword:(NSString*)encryptionPassword 
{	
	if ( _password != encryptionPassword ) 
	{
		[_password release];
		_password = [encryptionPassword copyWithZone:[self zone]];
	}
}

// DEPRECATED
- (JournlerEntry*) unpackageEntryAtPath:(NSString*)filepath 
{
	BOOL entry_encrypted;
	NSData	*readableData;
	JournlerEntry	*unarchivedObject = nil;
	
	NSString *packagePath, *archivePath, *encryptionPath;
	
	packagePath = filepath;
	
	//archivePath = [packagePath stringByAppendingPathComponent:PDEntryPackageEntryContents];
	NSArray *archivePossibilities = [[[NSFileManager defaultManager] directoryContentsAtPath:packagePath] 
			pathsMatchingExtensions:[NSArray arrayWithObject:@"jobj"]];
	if ( [archivePossibilities count] == 1 )
		archivePath = [packagePath stringByAppendingPathComponent:[archivePossibilities objectAtIndex:0]];
	else
	{
		NSLog(@"%@ %s - unable to locate entry contents at package path %@", [self className], _cmd, packagePath);
		return nil;
	}
	
	encryptionPath = [packagePath stringByAppendingPathComponent:PDEntryPackageEncrypted];
	
	NSData *objectData = [[NSData alloc] initWithContentsOfFile:archivePath];
	if ( !objectData ) 
	{
		NSLog(@"Unable to read object data at %@", packagePath);
		return nil;
	}
	
	readableData = objectData;
	entry_encrypted = NO;
	
	@try
	{
		unarchivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:readableData];
		
		// mark the entry's encryption flag
		[unarchivedObject setValue:[NSNumber numberWithBool:entry_encrypted] forKey:@"encrypted"];
	}
	@catch (NSException *localException)
	{
		unarchivedObject = nil;
		NSLog(@"%@ %s - unable to unarchive entry at path %@, exception %@", [self className], _cmd, filepath, localException);
		[_initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:0], @"objectType",
				filepath, @"errorString",
				localException, @"localException", nil]];
	}
	@finally
	{
		[objectData release];
		return unarchivedObject;
	}
}


#pragma mark -

- (JournlerCollection*) unarchiveCollectionAtPath:(NSString*)path 
{
	JournlerCollection *aCollection = nil;
	
	@try
	{
		aCollection = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	}
	@catch (NSException *localException)
	{
		aCollection = nil;
		NSLog(@"%@ %s - unable to unarchive folder at path %@, exception %@", [self className], _cmd, path, localException);
		[_initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:1], @"objectType",
				path, @"errorString",
				localException, @"localException", nil]];
	}
	@finally
	{
		return aCollection;
	}
}

- (BlogPref*) unarchiveBlogAtPath:(NSString*)path {
	
	BlogPref *blogPref = nil;
	
	@try
	{
		blogPref = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	}
	@catch (NSException *localException)
	{
		blogPref = nil;
		NSLog(@"%@ %s - unable to unarchive blog at path %@, exception %@", [self className], _cmd, path, localException);
		[_initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:2], @"objectType",
				path, @"errorString",
				localException, @"localException", nil]];
	}
	@finally
	{
		return blogPref;
	}
}

- (JournlerResource*) unarchiveResourceAtPath:(NSString*)path
{
	JournlerResource *aResource = nil;
	
	@try
	{
		aResource = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
	}
	@catch (NSException *localException)
	{
		aResource = nil;
		NSLog(@"%@ %s - unable to unarchive resource at path %@, exception %@", [self className], _cmd, path, localException);
		[_initErrors addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:3], @"objectType",
				path, @"errorString",
				localException, @"localException", nil]];
	}
	@finally
	{
		return aResource;
	}
}

#pragma mark -

#warning where do I ask for the collectionForID:-1
- (JournlerCollection*) collectionForID:(NSNumber*)idTag 
{
	if ( [idTag intValue] == -1 )
		return nil;
	else
		return [_foldersDic objectForKey:idTag];
}

#pragma mark -

- (NSArray*) collectionsForIDs:(NSArray*)tagIDs 
{
	//
	// utility for turning an array of collection ids into the collections themselves
	
	NSInteger i;
	NSMutableArray *collections = [[NSMutableArray alloc] initWithCapacity:[tagIDs count]];
	for ( i = 0; i < [tagIDs count]; i++ ) {
		id aCollection = [_foldersDic objectForKey:[tagIDs objectAtIndex:i]];
		if ( aCollection )
			[collections addObject:aCollection];
	}
	
	return [collections autorelease];
}

#pragma mark -

- (NSString*) pathForSupportDocumentOrDirectory:(JournlerSupportPath)identifier
{
	NSString *path = nil;
	switch ( identifier ) {
		case JournlerFoldersDirectory:
			path = [[self journalPath] stringByAppendingPathComponent:PDCollectionsLoc];
			break;
		case JournlerEntriesDirectory:
			path = [[self journalPath] stringByAppendingPathComponent:PDEntriesLoc];
			break;
		case JournlerBlogsDirectory:
			path = [[self journalPath] stringByAppendingPathComponent:PDJournalBlogsLoc];
			break;
		case JournlerResourcesDirectory:
			path = [[self journalPath] stringByAppendingPathComponent:PDJournalResourcesLocation];
			break;
		case JournlerDropBoxDirectory:
			path = [[self journalPath] stringByAppendingPathComponent:PDJournalDropBoxLocation];
			break;
		case JournlerPropertiesDocument:
			path = [[self journalPath] stringByAppendingPathComponent:PDJournalPropertiesLoc];
			break;
		case JournlerStoreDocument:
			path = [[self journalPath] stringByAppendingPathComponent:PDJournalStoreLoc];
			break;
	}
	
	return path;
}

#pragma mark -

- (NSDictionary*) entriesDictionary 
{ 
	return _entriesDic; 
}

- (NSDictionary*) collectionsDictionary 
{ 
	return _foldersDic; 
}

- (NSDictionary*) blogsDictionary { 
	return _blogsDic; 
}

- (NSDictionary*) resourcesDictionary
{
	return _resourcesDic;
}

- (NSDictionary*) entryWikisDictionary
{
	return _entryWikis;
}

- (NSSet*) entryTags
{
	return _entryTags;
}

#pragma mark -

- (BOOL) performOneTwoMaintenance {
	[_properties removeObjectForKey:@"Blogs"];
	[_properties removeObjectForKey:@"WikiLinks"];
	return YES;
} 

#pragma mark -

- (BOOL) hasChanges
{
	// if the journal object is dirty
	if ( [[self valueForKey:@"dirty"] boolValue] )
		return YES;
	
	NSInteger i;
	
	// or if any of the managed objects are dirty
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_entries); i++ )
	{
		if ( [[(id)CFArrayGetValueAtIndex((CFArrayRef)_entries,i) valueForKey:@"dirty"] boolValue] )
			return YES;
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_folders); i++ )
	{
		if ( [[(id)CFArrayGetValueAtIndex((CFArrayRef)_folders,i) valueForKey:@"dirty"] boolValue] )
			return YES;
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_resources); i++ )
	{
		if ( [[(id)CFArrayGetValueAtIndex((CFArrayRef)_resources,i) valueForKey:@"dirty"] boolValue] )
			return YES;
	}
	
	return NO;
}

- (BOOL) save:(NSError**)error
{
	// write the blogs, collections and entries to a single file
	
	NSInteger i;
	BOOL success;
	NSDictionary *store;
	NSMutableArray *theBlogs, *theEntries, *theCollections, *theResources;
	
	theBlogs = [[[NSMutableArray alloc] initWithCapacity:[_blogs count]] autorelease];
	theEntries = [[[NSMutableArray alloc] initWithCapacity:[_entries count]] autorelease];
	theCollections = [[[NSMutableArray alloc] initWithCapacity:[_folders count]] autorelease];
	theResources = [[[NSMutableArray alloc] initWithCapacity:[_resources count]] autorelease];
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_blogs); i++ )
	{
		NSData *encodedBlog = [NSKeyedArchiver archivedDataWithRootObject:(id)CFArrayGetValueAtIndex((CFArrayRef)_blogs,i)];
		[theBlogs addObject:encodedBlog];
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_entries); i++ )
	{
		NSDictionary *dictionary;
		NSData *encodedEntry = [NSKeyedArchiver archivedDataWithRootObject:(id)CFArrayGetValueAtIndex((CFArrayRef)_entries,i)];
		
		dictionary = [NSDictionary dictionaryWithObjectsAndKeys: encodedEntry, @"Data", nil];
		[theEntries addObject:dictionary];
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_folders); i++ )
	{
		NSData *encodedCollection = [NSKeyedArchiver archivedDataWithRootObject:(id)CFArrayGetValueAtIndex((CFArrayRef)_folders,i)];
		[theCollections addObject:encodedCollection];
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_resources); i++ )
	{
		NSData *encodedResource = [NSKeyedArchiver archivedDataWithRootObject:(id)CFArrayGetValueAtIndex((CFArrayRef)_resources,i)];
		[theResources addObject:encodedResource];
	}
	
	
	if ( [[self version] intValue] == 210 )
	{
		store = [NSDictionary dictionaryWithObjectsAndKeys:
		theBlogs, @"Blogs",
		theEntries, @"Entries",
		theCollections, @"Collections", nil];
	}
	else
	{
		store = [NSDictionary dictionaryWithObjectsAndKeys:
		theBlogs, @"Blogs",
		theEntries, @"Entries",
		theCollections, @"Collections",
		theResources, @"Resources", nil];
	}
	
	success = [store writeToFile:[self pathForSupportDocumentOrDirectory:JournlerStoreDocument] atomically:YES];
	if ( !success )
		NSLog(@"%@ %s - unable to write store to path %@", [self className], _cmd, 
				[self pathForSupportDocumentOrDirectory:JournlerStoreDocument]);
	
	// save the individual entries, collections and resources that are marked as dirty
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_entries); i++ )
	{
		JournlerEntry *anEntry = (id)CFArrayGetValueAtIndex((CFArrayRef)_entries,i);
		if ( [[anEntry valueForKey:@"dirty"] boolValue] )
		{
			[self saveEntry:anEntry];
		}
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_folders); i++ )
	{
		JournlerCollection *aCollection = (id)CFArrayGetValueAtIndex((CFArrayRef)_folders,i);
		if ( [[aCollection valueForKey:@"dirty"] boolValue] )
		{
			[self saveCollection:aCollection];
		}
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_resources); i++ )
	{
		JournlerResource *aResource = (id)CFArrayGetValueAtIndex((CFArrayRef)_resources,i);
		if ( [[aResource valueForKey:@"dirty"] boolValue] )
		{
			[self saveResource:aResource];
		}
	}
	
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_blogs); i++ )
	{
		BlogPref *aBlog = (id)CFArrayGetValueAtIndex((CFArrayRef)_blogs,i);
		if ( [[aBlog valueForKey:@"dirty"] boolValue] )
		{
			[self saveBlog:aBlog];
		}
	}

	
	// write the plist to disk
	[self saveProperties];
	// write the search indexes to disk
	[_searchManager writeIndexToDisk];
	// the journal is no longer dirty
	[self setValue:BooleanNumber(NO) forKey:@"dirty"];
	
	return success;
}

- (BOOL) saveEntry:(JournlerEntry*)entry
{	
	if ( entry == nil || [[entry valueForKey:@"deleted"] boolValue] )
		return NO;
	
	#ifdef __DEBUG__
	NSLog(@"%@ %s - %@ %@", [self className], _cmd, [entry valueForKey:@"tagID"], [entry valueForKey:@"title"]);
	#endif
	
	BOOL dir;
	NSError *writeError;
	NSString *packagePath, *propertiesPath, *RTFDPath, *RTFDContainer;
	
	NSData	*encodedProperties = [NSKeyedArchiver archivedDataWithRootObject:entry];
	NSAttributedString *attributedContent = [entry attributedContentIfLoaded];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// derive the required paths
	packagePath = [entry packagePath];
	
	// #warning what if the contents aren't there because of an error or something?
	NSArray *propertiesPossibilities = [[fm directoryContentsAtPath:packagePath] pathsMatchingExtensions:[NSArray arrayWithObject:@"jobj"]];
	if ( [propertiesPossibilities count] == 1 )
		propertiesPath = [packagePath stringByAppendingPathComponent:[propertiesPossibilities objectAtIndex:0]];
	else
		propertiesPath = [packagePath stringByAppendingPathComponent:PDEntryPackageEntryContents];
	
	RTFDContainer = [packagePath stringByAppendingPathComponent:PDEntryPackageRTFDContainer];
	RTFDPath = [RTFDContainer stringByAppendingPathComponent:PDEntryPackageRTFDContent];
	
	// ensure that a file exists at the package path
	if ( (![fm fileExistsAtPath:packagePath isDirectory:&dir] || !dir) && ![fm createDirectoryAtPath:packagePath attributes:nil] )
	{
		// critical error - unable to save entry
		NSLog(@"%@ %s - unable to create package for entry at path %@", [self className], _cmd, packagePath);
		return NO;
	}
	
	// create a file wrapper for the attributed content
	NSFileWrapper *rtfdWrapper = ( attributedContent == nil ? nil 
	: [attributedContent RTFDFileWrapperFromRange:NSMakeRange(0,[attributedContent length]) documentAttributes:nil] );
	
	if ( rtfdWrapper == nil && attributedContent != nil )
	{
		NSLog(@"%@ %s - unable to create file wrapper for entry content %@", 
				[self className], _cmd, [entry valueForKey:@"tagID"]);
	}
	
	// write the encoded properties
	if ( ![encodedProperties writeToFile:propertiesPath options:NSAtomicWrite error:&writeError] )
	{
		NSLog(@"%@ %s - unable to write encoded properties to file %@, error %@", [self className], _cmd, propertiesPath, writeError);
		return NO;
	}
	else
	{
		// rename the encoded properties
		#warning file manager ignores case?
		NSString *renamedPropertiesFilename = [NSString stringWithFormat:@"%@.jobj", [entry pathSafeTitle]];
		if ( ![[propertiesPath lastPathComponent] isEqualToString:renamedPropertiesFilename] )
			[fm movePath:propertiesPath toPath:[packagePath stringByAppendingPathComponent:renamedPropertiesFilename] handler:self];
	}
	
	// ensure that a directory exists for the entry text
	if ( ![fm fileExistsAtPath:RTFDContainer] && ![fm createDirectoryAtPath:RTFDContainer attributes:nil] )
	{
		NSLog(@"%@ %s - unable to create text container at path %@", [self className], _cmd, RTFDContainer);
		return NO;
	}
	
	// write the rich text
	if ( rtfdWrapper != nil && ![rtfdWrapper writeToFile:RTFDPath atomically:YES updateFilenames:YES] )
	{
		NSLog(@"%@ %s - unable to write rtfd to file %@", [self className], _cmd, RTFDPath);
		return NO;
	}
	
	// at this point the entry is ready for indexing and collection
	if ( !([self saveEntryOptions] & kEntrySaveDoNotIndex ) )
		[self _updateIndex:entry];
	
	if ( !([self saveEntryOptions] & kEntrySaveDoNotCollect) )
		[self _updateCollections:entry];
	
	// the entry is no longer dirty
	[entry setValue:BooleanNumber(NO) forKey:@"dirty"];
	// but the entry's resources are
	
	// go ahead and save the associated resoures as well?
	
	//[[entry valueForKey:@"resources"] setValue:BooleanNumber(NO) forKey:@"dirty"];

	return YES;
}

- (BOOL) saveResource:(JournlerResource*)aResource
{
	if ( aResource == nil 
			|| [[aResource valueForKey:@"deleted"] boolValue] 
			|| [[aResource valueForKey:@"tagID"] intValue] < 0 )
		return NO;

	if ( [[self version] intValue] >= 250 )
	{
		// derive a path to the colletion
		NSString *path = [[self pathForSupportDocumentOrDirectory:JournlerResourcesDirectory] 
				stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jresource", [aResource tagID]]];
		
		// update the collection's journal identifier
		[aResource setJournalID:[self identifier]];
		
		// archive the collection
		BOOL success = [NSKeyedArchiver archiveRootObject:aResource toFile:path];
		if ( !success )
		{
			NSLog(@"%@ %s - unable to archive resource %@ to path %@", 
					[self className], _cmd, [aResource valueForKey:@"tagID"], path);
			return NO;
		}
	}

	// resources are saved with an entry, so at this point the only thing to do is index it
	if ( !([self saveEntryOptions] & kEntrySaveDoNotIndex ) )
		[_searchManager indexResource:aResource owner:[aResource valueForKey:@"entry"]];
		
	[aResource setValue:BooleanNumber(NO) forKey:@"dirty"];
	
	return YES;
}

- (BOOL) saveCollection:(JournlerCollection*)aCollection
{
	if ( aCollection == nil || [[aCollection valueForKey:@"deleted"] boolValue] )
		return NO;
	
	// derive a path to the colletion
	NSString *path = [[self pathForSupportDocumentOrDirectory:JournlerFoldersDirectory] stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%@.jcol", [aCollection tagID]]];
	
	// update the collection's journal identifier
	[aCollection setJournalID:[self identifier]];
	
	// archive the collection
	BOOL success = [NSKeyedArchiver archiveRootObject:aCollection toFile:path];
	if ( !success )
	{
		NSLog(@"%@ %s - unable to archive collection %@ to path %@", 
				[self className], _cmd, [aCollection valueForKey:@"tagID"], path);
		return NO;
	}
	
	// the collection is no longer dirty
	[aCollection setValue:BooleanNumber(NO) forKey:@"dirty"];
	
	return YES;
}

- (BOOL) saveCollection:(JournlerCollection*)aCollection saveChildren:(BOOL)recursive 
{
	BOOL completeSuccess = YES;
	completeSuccess = [self saveCollection:aCollection];
	
	if ( recursive ) 
	{
		NSInteger i;
		NSArray *kids = [aCollection children];
		
		if ( kids != nil && [kids count] > 0 ) 
		{
			for ( i = 0; i < [kids count]; i++ )
				completeSuccess = ( [self saveCollection:[kids objectAtIndex:i] saveChildren:YES] && completeSuccess );
		}
	}
	
	return completeSuccess;
}

- (BOOL) saveBlog:(BlogPref*)aBlog
{
	if ( aBlog == nil || [[aBlog valueForKey:@"deleted"] boolValue] )
		return NO;
		
	// get the keychain data
	NSString *keychainUserName = [NSString stringWithFormat:@"%@-%@-%@", [aBlog blogType], [aBlog name], [aBlog login]];
	
	// remove the old keychain item
	if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" 
			withItemKind:@"BlogPassword" 
			forUsername:keychainUserName] ) 
	{
		[AGKeychain deleteKeychainItem:@"NameJournlerKey" 
				withItemKind:@"BlogPassword" 
				forUsername:keychainUserName];
	}

	// add the blog's password to the keychain
	[AGKeychain addKeychainItem:@"NameJournlerKey" 
			withItemKind:@"BlogPassword" 
			forUsername:keychainUserName 
			withPassword:[aBlog password]];
	
	//prepare the path to the blog
	NSString *path = [[self pathForSupportDocumentOrDirectory:JournlerBlogsDirectory] 
			stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jblog", [aBlog valueForKey:@"tagID"]]];
	
	// archive the blog
	BOOL success = [NSKeyedArchiver archiveRootObject:aBlog toFile:path];
	if ( !success)
	{
		NSLog(@"%@ %s - unable to archive blog %@ to path %@", 
				[self className], _cmd, [aBlog valueForKey:@"tagID"], path);
		return NO;
	}
	
	// the blog is no longer dirty
	[aBlog setValue:BooleanNumber(NO) forKey:@"dirty"];
		
	return YES;
}

#pragma mark -

- (void) addEntry:(JournlerEntry*)anEntry 
{	
	// ensure the entry has an appropriate id
	if ( [[anEntry valueForKey:@"tagID"] intValue] == 0 )
		[anEntry setValue:[NSNumber numberWithInt:[self newEntryTag]] forKey:@"tagID"];
	
	// journal relationship and scriptability
	[anEntry setValue:self forKey:@"journal"];
	[anEntry setScriptContainer:[self owner]];
	
	// add the entry to the library
	[[self libraryCollection] addEntry:anEntry];
	
	// add the entry to the dictionary
	if ( [_entriesDic objectForKey:[anEntry tagID]] == nil )
		[_entriesDic setObject:anEntry forKey:[anEntry tagID]];
	
	// add the entry to the entries array if its not there
	if ( [_entries indexOfObjectIdenticalTo:anEntry] == NSNotFound ) 
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillAddEntryNotification 
				object:self 
				userInfo:[NSDictionary dictionaryWithObject:anEntry 
				forKey:@"entry"]];
		
		[[self mutableArrayValueForKey:@"entries"] addObject:anEntry];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidAddEntryNotification 
				object:self 
				userInfo:[NSDictionary dictionaryWithObject:anEntry 
				forKey:@"entry"]];
	}
}

- (void) addCollection:(JournlerCollection*)aCollection 
{	
	// ensure an appropriate id
	if ( [[aCollection valueForKey:@"tagID"] intValue] == 0 )
		[aCollection setValue:[NSNumber numberWithInt:[self newFolderTag]] forKey:@"tagID"];
	
	// ensure a default sort
	if ( [[aCollection valueForKey:@"sortDescriptors"] count] == 0 )
	{
		NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] initWithKey:@"title" 
				ascending:YES 
				selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
				
		[aCollection setValue:[NSArray arrayWithObject:titleSort] forKey:@"sortDescriptors"];
	}
	
	// establish a relationship to the journal
	[aCollection setValue:self forKey:@"journal"];
	[aCollection setScriptContainer:[self owner]];
	
	// add the collection to the dictionary and array
	[_foldersDic setObject:aCollection forKey:[aCollection tagID]];
	
	// add the collection to the collections array if its not there
	if ( [_folders indexOfObjectIdenticalTo:aCollection] == NSNotFound ) 
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillAddFolderNotification
				object:self 
				userInfo:[NSDictionary dictionaryWithObject:aCollection 
				forKey:@"folder"]];
		
		[[self mutableArrayValueForKey:@"collections"] addObject:aCollection];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidAddFolderNotification 
				object:self 
				userInfo:[NSDictionary dictionaryWithObject:aCollection 
				forKey:@"folder"]];
	}
	
	// save the collection
	[self saveCollection:aCollection];
}

- (JournlerResource*) addResource:(JournlerResource*)aResource
{
	if ( aResource == nil )
		return nil;
	
	NSUInteger resourceIndex;
	JournlerResource *returnResource = nil;
	
	resourceIndex = [[self valueForKey:@"resources"] indexOfObject:aResource];
	
	// add the resource to the journal's array
	if ( resourceIndex == NSNotFound )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillAddResourceNotificiation
				object:self 
				userInfo:[NSDictionary dictionaryWithObject:aResource 
				forKey:@"resource"]];
		
		// establish the relationship to the journal and scripitability
		[aResource setValue:self forKey:@"journal"];
		[aResource setScriptContainer:[self owner]];
		
		// add the resource to the dictionary
		[_resourcesDic setObject:aResource forKey:[aResource tagID]];
		
		[[self mutableArrayValueForKey:@"resources"] addObject:aResource];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidAddResourceNotification
				object:self 
				userInfo:[NSDictionary dictionaryWithObject:aResource 
				forKey:@"resource"]];
		
		// save the resource
		[self saveResource:aResource];
		
		returnResource = aResource;
		
		//return YES;
	}
	else
	{
		returnResource = [[self valueForKey:@"resources"] objectAtIndex:resourceIndex];
		//return NO;
	}
	
	return returnResource;
}

#pragma mark -

- (BOOL) deleteEntry:(JournlerEntry*)anEntry
{	
	if ( anEntry == nil )
		return NO;
	
	BOOL success;
	[anEntry retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillDeleteEntryNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:anEntry 
			forKey:@"entry"]];

	// remove the entries from this resource, relocating them if necessary
	NSArray *errors;
	if ( ![self removeResources:[anEntry resources] fromEntries:[NSArray arrayWithObject:anEntry] errors:&errors] )
	{
		// need a way of getting these entries to the user
		NSLog(@"%@ %s - there were problems removing the resource from entry %@", [self className], _cmd, [anEntry tagID]);
	}

	// path info for the physical delete
	NSString *full_path = [anEntry packagePath];
	
	// remove the file from searching
	[_searchManager removeEntry:anEntry];
	
	// remove the file from any collections	-- recursively
	[[self collections] makeObjectsPerformSelector:@selector(removeEntry:) withObject:anEntry];
	
	// physically delete the file
	success = ( [[NSFileManager defaultManager] removeFileAtPath:full_path handler:self] );

	// mark the entry as deleted in case its being held elsewhere
	[anEntry setValue:BooleanNumber(YES) forKey:@"deleted"];
	
	// mark the entries resources as being deleted
	//[[anEntry valueForKey:@"resources"] setValue:[NSNumber numberWithBool:YES] forKey:@"deleted"];
	
	// remove the entry from the dictionary
	[_entriesDic removeObjectForKey:[anEntry valueForKey:@"tagID"]];
	
	// remove the entry from the entries array -- was jusing removeObjectIdenticalTo: -- why?
	[[self mutableArrayValueForKey:@"entries"] removeObject:anEntry];
	
	// remove any tags that are not longer being used
	if ( [[anEntry valueForKey:@"tags"] count] != 0 )
	{
		NSSet *thisEntrysTags = [NSSet setWithArray:[anEntry valueForKey:@"tags"]];
				
		NSString *aTag;
		NSEnumerator *enumerator = [thisEntrysTags objectEnumerator];
		
		while ( aTag = [[enumerator nextObject] lowercaseString] )
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ in tags.lowercaseString AND markedForTrash == NO",aTag];
			if ( [[[self entries] filteredArrayUsingPredicate:predicate] count] == 0 )
				[_entryTags removeObject:aTag];
		}
		
		//NSLog([_entryTags description]);
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidDeleteEntryNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:anEntry 
			forKey:@"entry"]];
	
	// release the entry now that we're finished
	[anEntry release];
	
	return success;
}

- (BOOL) deleteResource:(JournlerResource*)aResource
{
	if ( aResource == nil )
		return NO;
	
	BOOL success = YES;
	[aResource retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillDeleteResourceNotificiation 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:aResource 
			forKey:@"resource"]];
	
	// remove the resource from the search index
	[[self searchManager] removeResource:aResource owner:[aResource valueForKey:@"entry"]];
	
	// remove the resource from the entry
	[[aResource valueForKey:@"entry"] removeResource:aResource];
	
	if ( [aResource representsFile] )
	{
		// if the resource is file based, delete it
		if ( [[NSFileManager defaultManager] fileExistsAtPath:[aResource path]] 
			&& ![[NSFileManager defaultManager] removeFileAtPath:[aResource path] handler:self] )
		{
			success = NO;
			NSLog(@"%@ %s - problem removing file based resource at path %@", [self className], _cmd, [aResource path]);
		}
		
		if ( [[NSFileManager defaultManager] fileExistsAtPath:[aResource _thumbnailPath]] 
				&& ![[NSFileManager defaultManager] removeFileAtPath:[aResource _thumbnailPath] handler:self] )
		{
			NSLog(@"%@ %s - problem removing icon for file based resource at path %@", [self className], _cmd, [aResource path]);
		}
	}
	else if ( [aResource representsURL] )
	{
		// delete the url thumbnail
		if ( [[NSFileManager defaultManager] fileExistsAtPath:[aResource _thumbnailPath]] 
				&& ![[NSFileManager defaultManager] removeFileAtPath:[aResource _thumbnailPath] handler:self] )
		{
			NSLog(@"%@ %s - problem removing icon for file based resource at path %@", [self className], _cmd, [aResource path]);
		}
	}
	else if ( [aResource representsJournlerObject] )
	{
		#warning if the resource is a link to another entry, delete the reverse link?
		NSURL *uri = [NSURL URLWithString:[aResource valueForKey:@"uriString"]];
		if ( [uri isJournlerEntry] )
		{
			JournlerEntry *theReverseEntry = [self objectForURIRepresentation:uri];
			if ( theReverseEntry == nil )
			{
				NSLog(@"%@ %s - error deriving entry for reverse link delete", [self className], _cmd);
			}
			else
			{
				NSString *myEntryURIString = [[[aResource valueForKey:@"entry"] URIRepresentation] absoluteString];
				
				JournlerResource *aReverseResource;
				NSEnumerator *reverseEntryResourceEnumerator = [[theReverseEntry valueForKey:@"resources"] objectEnumerator];
				
				while ( aReverseResource = [reverseEntryResourceEnumerator nextObject] )
				{
					if ( [aReverseResource representsJournlerObject] && 
							[myEntryURIString isEqualToString:[aReverseResource valueForKey:@"uriString"]] )
					{
						
						[aReverseResource retain];
						
						// remove the reverse resource from the journal
						[_resources removeObject:aReverseResource];
						[_resourcesDic removeObjectForKey:[aReverseResource valueForKey:@"tagID"]];
						
						// remove the reverse resource from the entry
						[theReverseEntry removeResource:aReverseResource];
						
						[aReverseResource release];
						break;
					}
				}
			}
		}
	}
	
	// and actually delete the resoure file in the resources directory
	NSString *journalResourcePath = [[self pathForSupportDocumentOrDirectory:JournlerResourcesDirectory] 
			stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jresource", [aResource tagID]]];
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:journalResourcePath] 
			&& ![[NSFileManager defaultManager] removeFileAtPath:journalResourcePath handler:self] )
		NSLog(@"%@ %s - problem deleting the physical representation of the resource at %@", [self className], _cmd, journalResourcePath);
	
	// mark the entry as deleted
	[aResource setValue:BooleanNumber(YES) forKey:@"deleted"];
	
	// remove the resource from the dictionary
	[_resourcesDic removeObjectForKey:[aResource valueForKey:@"tagID"]];
	
	// remove the resource from the array
	[[self mutableArrayValueForKey:@"resources"] removeObject:aResource];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidDeleteResourceNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:aResource 
			forKey:@"resource"]];
	
	[aResource release];
	return success;
}

- (BOOL) deleteCollection:(JournlerCollection*)collection deleteChildren:(BOOL)children 
{
	if ( collection == nil )
		return NO;
	
	BOOL success = YES;
	[collection retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillDeleteFolderNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:collection 
			forKey:@"folder"]];
	
	// first the children
	if ( children ) 
	{
		NSInteger i;
		NSArray *kids = [[[collection children] copyWithZone:[self zone]] autorelease];
		for ( i = 0; i < [kids count]; i++ )
			[self deleteCollection:[kids objectAtIndex:i] deleteChildren:YES];
	}
	
	// get the collections path
	NSString *fullPath = [[self pathForSupportDocumentOrDirectory:JournlerFoldersDirectory] 
			stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jcol", [collection valueForKey:@"tagID"]]];
		
	// remove the collection from its parent
	JournlerCollection *parentNode = [(JournlerCollection*)collection parent];
	if ( parentNode != nil ) [parentNode removeChild:collection recursively:NO];
	else [self removeRootFolder:collection];
	
	// remove the collection each of its entries 
	// - should this be performed in the collections dealloc?
	NSInteger i;
	NSArray *entries = [collection valueForKey:@"entries"];
	for ( i = 0; i < [entries count]; i++ )
		[[[entries objectAtIndex:i] mutableArrayValueForKey:@"collections"] removeObject:collection];
	
	// remove the collection from the computer
	if ( fullPath ) success = [[NSFileManager defaultManager] removeFileAtPath:fullPath handler:self];
	else success = NO;
	
	// mark the collection as deleted in case anyone is still holding on to it
	[collection setValue:BooleanNumber(YES) forKey:@"deleted"];
	
	// remove the collection from the dictionary and the array
	[_foldersDic removeObjectForKey:[collection tagID]];
	
	// remove the collections from the array
	[[self mutableArrayValueForKey:@"collections"] removeObject:collection];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidDeleteFolderNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:collection 
			forKey:@"folder"]];
	
	// an release it
	[collection release];
	
	return success;
}

- (BOOL) deleteBlog:(BlogPref*)aBlog
{
	if ( aBlog == nil )
		return NO;
	
	[aBlog retain];
	
	// make sure the blog exists to be removed
	if ( [_blogs indexOfObjectIdenticalTo:aBlog] == NSNotFound ) 
		return NO;
		
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalWillDeleteBlogNotification
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:aBlog forKey:@"blog"]];
	
	// remove the keychain information
	NSString *keychainUserName = [NSString stringWithFormat:@"%@-%@-%@", [aBlog blogType], [aBlog name], [aBlog login]];

	if ( [AGKeychain checkForExistanceOfKeychainItem:@"NameJournlerKey" 
			withItemKind:@"BlogPassword" 
			forUsername:keychainUserName] ) {
		
		[AGKeychain deleteKeychainItem:@"NameJournlerKey" 
				withItemKind:@"BlogPassword" 
				forUsername:keychainUserName];
	
	}

	// physically delete the blog
	NSString *path = [[self pathForSupportDocumentOrDirectory:JournlerBlogsDirectory] 
			stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jblog", [aBlog valueForKey:@"tagID"]]];

	if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
		if ( ![[NSFileManager defaultManager] removeFileAtPath:path handler:self] )
			NSLog(@"%@ %s - trouble removing blog at path %@", [self className], _cmd, path);
	}
	
	// update the dictionary
	[_blogsDic removeObjectForKey:[aBlog tagID]];

	// remove the blog from the array
	NSMutableArray *temp = [[[self blogs] mutableCopyWithZone:[self zone]] autorelease];
	[temp removeObject:aBlog];
	[self setBlogs:temp];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JournalDidDeleteBlogNotification
			object:self userInfo:[NSDictionary dictionaryWithObject:aBlog forKey:@"blog"]];
	
	[aBlog release];
	
	return YES;
}

#pragma mark -
#pragma mark Root Folder Utilities

- (void) addRootFolder:(JournlerCollection*)subfolder atIndex:(NSUInteger)index 
{	
	// check to make sure the index is not over or that we want the item to be last
	if ( index == -1 || index > [self countOfRootFolders] ) 
		index = [self countOfRootFolders];
	
	// set the folder's script container
	[subfolder setScriptContainer:[self owner]];
	
	// set the parent
	[subfolder setParent:nil];
	[subfolder setParentID:nil];

	// insert the child at the index
	[subfolder setValue:[NSNumber numberWithInt:index] forKey:@"index"];
	[[self mutableArrayValueForKey:@"rootFolders"] insertObject:subfolder atIndex:index];
	
	// all the children this and after must have their index values adjusted
	NSInteger i;
	for ( i = index; i < [self countOfRootFolders]; i++ )
		[[self objectInRootFoldersAtIndex:i] setValue:[NSNumber numberWithInt:i] forKey:@"index"];
}

- (void)removeRootFolder:(JournlerCollection*)subfolder
{
	[subfolder retain];
	
	NSInteger old_index = [[self rootFolders] indexOfObjectIdenticalTo:subfolder];
	[[self mutableArrayValueForKey:@"rootFolders"] removeObject:subfolder];
		
	// all the children this and after must have their index values adjusted
	NSInteger i;
	for ( i = old_index; i < [self countOfRootFolders]; i++ )
		[[self objectInRootFoldersAtIndex:i] setValue:[NSNumber numberWithInt:i] forKey:@"index"];
	
	[subfolder release];
}

- (void) moveRootFolder:(JournlerCollection *)aFolder toIndex:(NSUInteger)anIndex
{
	if ( anIndex > [[aFolder valueForKey:@"index"] intValue] )
		anIndex--;
	
	[aFolder retain];
	[self removeRootFolder:aFolder];
	[self addRootFolder:aFolder atIndex:anIndex];
	[aFolder release];
}

#pragma mark -
#pragma mark Resource <-> Entry Utilities

- (JournlerEntry*) bestOwnerForResource:(JournlerResource*)aResource
{
	// finds the best possible entry owner for the resource in question
	// returns nil if none is available
	
	JournlerEntry *bestOwner = nil;
	
	if ( [aResource entry] != nil )
		bestOwner = [aResource entry];
		// ideally the resource already has an owning entry - that would be the best one
	
	else
	{
		if ( [aResource representsFile] )
		{
			// take one course of action if the resource represents a file - associate it with the entry where that file actually is
			
			// first have a look at any entries still registed with the resource
			NSArray *allOwners = [aResource entries];
			
			JournlerEntry *anEntry;
			NSEnumerator *entryEnumerator = [allOwners objectEnumerator];
			
			while ( anEntry = [entryEnumerator nextObject] )
			{
				if ( [anEntry resourcesIncludeFile:[aResource filename]] )
				{
					bestOwner = anEntry;
					// the file represented by this resource is contained in this entry, re-attach it
					break;
				}
			}
			
			// at this point, bestOwner could still be nil, so go through the entire journal looking for an entry
			
			entryEnumerator = [[self entries] objectEnumerator];
			
			while ( anEntry = [entryEnumerator nextObject] )
			{
				if ( [anEntry resourcesIncludeFile:[aResource filename]] )
				{
					bestOwner = anEntry;
					// the file represented by this resource is contained in this entry, re-attach it
					break;
				}
			}
			
			// the bestOwner could still be nil, in which case the resource is lost
			// recovery options include a spotlight search, narrowed to the uti type and filename
		}
		
		else
		{
			// simpler, take the first available entry
			NSArray *allOwners = [aResource entries];
			
			if ( [allOwners count] > 0 )
				bestOwner = [allOwners objectAtIndex:0];
				// just take the first available owner
				
			else
			{
				// the resource isn't seeing any other owners, so comb the entries looking for one that might contain this resource
				
				JournlerEntry *anEntry;
				NSEnumerator *entryEnumerator = [[self entries] objectEnumerator];
				
				while ( anEntry = [entryEnumerator nextObject] )
				{
					if ( [[anEntry resources] containsObject:aResource] )
					{
						bestOwner = anEntry;
						// the entry has not lost the resource relationship - re-attach the resource to the entry
						break;
					}
				}
				
				// its possible best owner could still be nil at this point, in which case the resource really is lost
			}
		}
	}
	
	return bestOwner;
}

- (JournlerResource*) alreadyExistingResourceWithType:(JournlerResourceType)type 
		data:(id)anObject
		operation:(NewResourceCommand)command
{
	// looks at the data and attempts to find an already existing resource that matches it.
	// uses predicate filtering
	
	NSString *typeString = nil;
	NSArray *potentialMatches = nil;
	JournlerResource *matchingResource = nil;
	
	NSPredicate *dataPredicate = nil;
	NSPredicate *typePredicate = [NSPredicate predicateWithFormat:@"type == %i", type];
	NSPredicate *combinedPredicate = nil;
	
	// build the predicates
	switch ( type )
	{
	case kResourceTypeABRecord:
		if ( [anObject isKindOfClass:[NSString class]] )
		{
			typeString = @"AB Contact";
			//dataPredicate = [NSPredicate predicateWithFormat:@"uniqueId MATCHES %@", anObject];
			dataPredicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", anObject];
		}
		break;
	
	case kResourceTypeURL:
		if ( [anObject isKindOfClass:[NSString class]] )
		{
			typeString = @"URL";
			//dataPredicate = [NSPredicate predicateWithFormat:@"urlString MATCHES %@", anObject];
			dataPredicate = [NSPredicate predicateWithFormat:@"urlString == %@", anObject];
		}
		break;
	
	case kResourceTypeJournlerObject:
		if ( [anObject isKindOfClass:[NSString class]] )
		{
			typeString = @"Internal Link";
			//dataPredicate = [NSPredicate predicateWithFormat:@"uriString MATCHES %@", anObject];
			dataPredicate = [NSPredicate predicateWithFormat:@"uriString == %@", anObject];
		}
		break;
	
	case kResourceTypeFile:
		if ( [anObject isKindOfClass:[NSString class]] )
		{
			typeString = @"File";
			//dataPredicate = [NSPredicate predicateWithFormat:@"filename MATCHES %@", [anObject lastPathComponent]];
			//dataPredicate = [NSPredicate predicateWithFormat:@"originalPath MATCHES %@", anObject];
			dataPredicate = [NSPredicate predicateWithFormat:@"originalPath == %@", anObject];
		}
		break;
	}
	
	// bail if either of the predicates could not be established
	if ( dataPredicate == nil || typePredicate == nil )
		goto bail;
	
	// for contacts, urls and journler objects a simple match is enough
	// for files a path match is also required, so check the original path on any returns
	
	combinedPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:typePredicate, dataPredicate, nil]];
	potentialMatches = [[self resources] filteredArrayUsingPredicate:combinedPredicate];
	
	if ( [potentialMatches count] == 0 )
		goto bail;
	
	if ( type == kResourceTypeABRecord || type == kResourceTypeURL || type == kResourceTypeJournlerObject )
		matchingResource = [potentialMatches objectAtIndex:0];
	
	else if ( type == kResourceTypeFile )
	{
		JournlerResource *aResource;
		NSEnumerator *enumerator = [potentialMatches objectEnumerator];
		
		while ( aResource = [enumerator nextObject] )
		{
			if ( [[aResource originalPath] isEqualToString:anObject] 
					&& ( ( [aResource isAlias] && command == kNewResourceForceLink ) || ( ![aResource isAlias] && command == kNewResourceForceCopy ) ) )
			{
				// unlike the other resource queries, make sure the alias vs copy matches
				matchingResource = aResource;
				break;
			}
		}
	}
	
	// and finally, note that a resources matching the conditions was found
	// also note if there was a potential file match but none used - it would be cool if the user could request that one be used
	
bail:
	
	if ( matchingResource == nil )
	{
		[_activity appendFormat:@"No matching resource found for new media, creating new resource.\n\t-- Media Type: %@\n\t-- Information: %@\n", typeString, anObject];
		if ( type == kResourceTypeFile && [potentialMatches count] > 0 )
		{
			[_activity appendFormat:@"There were potential matches for the new resources.\n"];
			
			JournlerResource *aResource;
			NSEnumerator *enumerator = [potentialMatches objectEnumerator];
			
			while ( aResource = [enumerator nextObject] )
				[_activity appendFormat:@"\t-- Name: %@\n\t-- ID: %@\n\t-- Path: %@\n", [aResource title], [aResource tagID], [aResource originalPath]];
		}
	}
	else
	{
		[_activity appendFormat:@"Matching resource found for new media, using previously created resource.\n\t-- Media Type: %@\n\t-- Information: %@\n\t --Resource Name: %@\n\t-- Resource ID: %@\n", typeString, anObject, [matchingResource valueForKey:@"title"], [matchingResource valueForKey:@"tagID"]];
	}
	
	[self setActivity:_activity];
	
	return matchingResource;
}

- (BOOL) removeResources:(NSArray*)resourceArray 
		fromEntries:(NSArray*)entriesArray 
		errors:(NSArray**)errorsArray
{
	// resources are removed from the listed entries
	// if the entry is the resources owner, the resource is moved to a different owner
	// note that when an entry is deleted, resources must also be moved around
	
	#warning when moving a url also delete the preview in the old location
	
	BOOL success = YES;
	
	#ifdef __DEBUG__
	NSLog(@"%@ %s", [self className], _cmd);
	#endif
	
	JournlerResource *aResource;
	NSEnumerator *resourceEnumerator = [resourceArray objectEnumerator];
	
	while ( aResource = [resourceEnumerator nextObject] )
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if ( [[aResource entries] containsAnObjectInArray:entriesArray] )
		{
			NSMutableArray *resourcesEntries = [[[aResource entries] mutableCopyWithZone:[self zone]] autorelease];
			
			// remove the entries from the resource - the resource -> entry relationship must change first
			[resourcesEntries removeObjectsInArray:entriesArray];
			[aResource setEntries:resourcesEntries];
			
			// remove the resource from each entry in the array
			[entriesArray makeObjectsPerformSelector:@selector(removeResource:) withObject:aResource];
			
			// check to make sure the resource's parent is still in the entries list
			if ( ![resourcesEntries containsObject:[aResource entry]] )
			{
				[_activity appendFormat:@"Resource no longer belongs to parent, taking action...\n\t-- Name: %@\n\t-- ID: %@\n", [aResource title], [aResource tagID]];
				
				// if the resources has no more entries, delete it
				if ( [resourcesEntries count] == 0 )
				{
					[_activity appendString:@"Resource no longer belongs to any entries, deleting it\n"];
					
					#ifdef __DEBUG__
					NSLog(@"%@ %s - resource %@ no longer belongs to any entries, deleting it", [self className], _cmd, [aResource tagID]);
					#endif
				
					[self deleteResource:aResource];
				}
				else
				{
					// move the resource to the first other entry
					JournlerEntry *oldParent = [aResource entry];
					JournlerEntry *newParent = [resourcesEntries objectAtIndex:0];
					
					if ( [aResource representsFile] )
					{
						// the resource must be moved - here is the possibility for errors
						NSString *oldPath = [aResource path];
						NSString *oldFilename = [aResource filename];
						
						NSString *newPathDirectory = [newParent resourcesPathCreating:YES];
						if ( newPathDirectory == nil )
						{
							success = NO;
							[_activity appendFormat:@"** Moving resource to new entry, but there was a problem creating the new destination directory...\n\t-- Destination Entry: %@\n\t-- Destination ID: %@\n", [newParent title], [newParent tagID]];
							
							NSLog(@"%@ %s - problem creating resource directory for entry %@ to move entry %@",
							[self className], _cmd, [newParent tagID], [aResource tagID]);
						}
						else
						{
							// derive a new target for the file
							NSString *newPath = [[newPathDirectory stringByAppendingPathComponent:oldFilename] pathWithoutOverwritingSelf];
							NSString *newFilename = [newPath lastPathComponent];
							
							#ifdef __DEBUG__
							NSLog(@"%@ %s - moving resource %@ from %@ to %@", [self className], _cmd, [aResource tagID], oldPath, newPath);
							#endif
							
							if ( [[NSFileManager defaultManager] movePath:oldPath toPath:newPath handler:self] )
							{
								// remove the icon representation
								if ( [[NSFileManager defaultManager] fileExistsAtPath:[aResource _thumbnailPath]] )
									[[NSFileManager defaultManager] removeFileAtPath:[aResource _thumbnailPath] handler:self];
								
								// re-parent the resource
								[aResource setEntry:newParent];
								
								// the resource takes on the filename available at its new location (could have changed)
								[aResource setFilename:newFilename];
								
								// log the changes
								[_activity appendFormat:@"Successfully moved resource to new parent...\n\t-- Destination Entry: %@\n\t-- Destination ID: %@\n", [newParent title], [newParent tagID]];
							}
							else
							{
								// problem making the move
								success = NO;
								
								[_activity appendFormat:@"** There was a problem moving the entry to a new parent...\n\t-- Old Parent: %@\n\t-- Old Parent ID: %@\n\t-- Destination Entry: %@\n\t-- Destination ID: %@\n", [oldParent title], [oldParent tagID], [newParent title], [newParent tagID]];
								
								NSLog(@"%@ %s - problem moving resource %@ from %@ to %@", [self className], _cmd, [aResource tagID], oldPath, newPath);
								
								// set the resource back in the entry
								[[aResource entry] addResource:aResource];
							}
						}
					}
					
					else
					{
						// easy - just re-parent the resource
						[aResource setEntry:newParent];
						
						// log the changes
						[_activity appendFormat:@"Successfully moved resource to new parent...\n\t-- Destination Entry: %@\n\t-- Destination ID: %@\n", [newParent title], [newParent tagID]];
					}
					
					#ifdef __DEBUG__
					NSLog(@"%@ %s - moved resource %@ from entry %@ to entry %@", [self className], _cmd, [aResource tagID], [oldParent tagID], [newParent tagID]);
					#endif
					
					// save the resource
					if ( ![self saveResource:aResource] )
					{
						success = NO;
						NSLog(@"%@ %s - problem saving resource %@ after changing its parent to entry %@",
						[self className], _cmd, [aResource tagID], [newParent tagID]);
					}
					
				}
			}
		}
				
		[pool release];
	}
	
	// save all of the entries
	JournlerEntry *anEntry;
	NSEnumerator *entrySaveEnumerator = [entriesArray objectEnumerator];
	
	while ( anEntry = [entrySaveEnumerator nextObject] )
	{
		if ( ![self saveEntry:anEntry] )
		{
			success = NO;
			NSLog(@"%@ %s - problem saving entry %@", [self className], _cmd, [anEntry tagID]);
		}
	}
	
	// note the activity
	[self setActivity:_activity];
	
	return success;
}

#pragma mark -
#pragma mark File Manager Delegation

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo 
{
	NSLog(@"\n%@ %s - Encountered file manager error: source = %@, error = %@, destination = %@\n", [self className], _cmd,
			[errorInfo objectForKey:@"Path"], [errorInfo objectForKey:@"Error"], [errorInfo objectForKey:@"ToPath"]);
	
	return NO;
	
}

- (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path 
{
	// for consistency. method does nothing
}

#pragma mark -
#pragma mark memory management

- (void) checkMemoryUse:(id)anObject
{
	#ifdef __DEBUG__
	NSLog(@"%@ %s",[self className],_cmd);
	#endif
	
	// run this in the background
	[NSThread detachNewThreadSelector:@selector(_checkMemoryUse:) 
			toTarget:self 
			withObject:anObject];
}

- (void) _checkMemoryUse:(id)anObject
{
	// the deal:
	// every ten minutes check every object for its last content access
	// if that last access occurred longer than ten minutes ago, and there is no interface lock, release the content
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSInteger i;
	NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
	
	// do not index or collect entries, which should already be indexed and collected
	NSInteger lastSaveOptions = [self saveEntryOptions];
	[self setSaveEntryOptions:(kEntrySaveDoNotIndex|kEntrySaveDoNotCollect)];
	
	// or if any of the managed objects are dirty
	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_entries); i++ )
	{
		JournlerEntry *anEntry = (JournlerEntry*)CFArrayGetValueAtIndex((CFArrayRef)_entries,i);
		NSTimeInterval lastContentAccess = [anEntry lastContentAccess];
		
		if ( lastContentAccess != 0 
				&& (currentTime - lastContentAccess) > (10*60) 
				&& [anEntry contentRetainCount] <= 0 
				&& [anEntry attributedContentIfLoaded] != nil )
		{
			#ifdef __DEBUG__
			NSLog(@"%@ %s - releasing the content for entry %@-%@", [self className], _cmd, [anEntry tagID], [anEntry title]);
			#endif
			
			// save the entry if it is dirty
			if ( [[anEntry dirty] boolValue] )
				[self saveEntry:anEntry];
			
			// unload the content from memory
			[anEntry unloadAttributedContent];
		}
	}

	for ( i = 0; i < CFArrayGetCount((CFArrayRef)_resources); i++ )
	{
		JournlerResource *aResource = (JournlerResource*)CFArrayGetValueAtIndex((CFArrayRef)_resources,i);
		NSTimeInterval lastPreviewAccess = [aResource lastPreviewAccess];
		
		if ( lastPreviewAccess != 0 
				&& (currentTime - lastPreviewAccess) > (10*60) 
				&& [aResource previewRetainCount] <= 0 
				&& [aResource previewIfLoaded] != nil )
		{
			#ifdef __DEBUG__
			NSLog(@"%@ %s - releasing the content for entry %@-%@", [self className], _cmd, [aResource tagID], [aResource title]);
			#endif
			
			[aResource unloadPreview];
		}
	}
	
	// reset the save entry options
	[self setSaveEntryOptions:lastSaveOptions];
	
	[pool release];
}

- (void) checkForModifiedResources:(id)anObject
{
	[NSThread detachNewThreadSelector:@selector(_checkForModifiedResources:) 
			toTarget:self 
			withObject:nil];
}

- (void) _checkForModifiedResources:(id)anObject
{
	// check the date modified for the file resources against what I have
	// if different, reload icon and re-index.
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	JournlerResource *aResource;
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	
	#ifdef __DEBUG__
	NSLog(@"%@ %s - beginning at %@",[self className],_cmd,[NSDate date]);
	#endif
	
	while ( aResource = [enumerator nextObject] )
	{
		if ( [aResource representsFile] )
		{
			NSString *path = [aResource originalPath];
			if ( path != nil )
			{
				NSDictionary *fileAttributes = [fm fileAttributesAtPath:path traverseLink:YES];
				
				NSDate *savedDateModified = [aResource valueForKey:@"underlyingModificationDate"];
				NSDate *actualDateModified = [fileAttributes objectForKey:NSFileModificationDate];
				
				if ( savedDateModified != nil 
						&& actualDateModified != nil 
						&& [savedDateModified compare:actualDateModified] == NSOrderedAscending )
				{
					#ifdef __DEBUG__
					NSLog(@"%@ %s - resource has been modified, path %@", [self className], _cmd, path);
					#endif
					
					[aResource reloadIcon];
					[aResource setValue:actualDateModified forKey:@"underlyingModificationDate"];
					//[aResource setValue:nil forKey:@"icon"];
					
					[[self searchManager] indexResource:aResource owner:[aResource valueForKey:@"entry"]];
				}
			}
		}
	}
	
	#ifdef __DEBUG__
	NSLog(@"%@ %s - ending at %@",[self className],_cmd,[NSDate date]);
	#endif
	
	[pool release];
}

@end

#pragma mark -

@implementation JournlerJournal (ConsoleUtilities)

- (BOOL) resetSmartFolders
{
	NSInteger i;
	NSArray *allEntries = [self entries];
	for ( i = 0; i < [allEntries count]; i++ )
		[self _updateCollections:[allEntries objectAtIndex:i]];
	
	return YES;
}

- (BOOL) resetSearchManager 
{
	NSLog(@"%@ %s - Rebuilding search index", [self className], _cmd);
	
	// Clear out the old manager
	if ( _searchManager ) 
	{
		[_searchManager release];
		_searchManager = nil;
	}
	
	// Realloc
	_searchManager = [[JournlerSearchManager alloc] initWithJournal:self];
	if ( !_searchManager ) {
		NSLog(@"%@ %s - Unable to reallocate search manager, searching disabled", [self className], _cmd);
		return NO;
	}
	
	// Delete any existing indexes and re-create them
	[_searchManager deleteIndexAtPath:[self journalPath]];

	// reload the index
	if ( ![_searchManager createIndexAtPath:[self journalPath]] || ![_searchManager loadIndexAtPath:[self journalPath]] )
	{
		NSLog(@"%@ %s - Unable to recreate or reload index at journal path %@", [self className], _cmd, [self journalPath]);
		return NO;
	}
	
	// rederive the textual representations
	JournlerResource *aResource;
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	while ( aResource = [enumerator nextObject] )
		[aResource _deriveTextRepresentation:nil];
	
	// Rebuild the indexes
	[_searchManager rebuildIndex];
		
	NSLog(@"%@ %s - Search reset successful", [self className], _cmd);
	return YES;
}

- (BOOL) resetEntryDateModified 
{	
	NSInteger i;
	
	NSLog(@"Resetting date modified property of journal entry objects");
	
	for ( i = 0; i < [_entries count]; i++ ) {
		
		// reset the date
		[(JournlerEntry*)[_entries objectAtIndex:i] 
				setCalDateModified:[(JournlerEntry*)[_entries objectAtIndex:i] calDate]];
		
		// update the entry against collections testing the date modified property
		[self _updateCollections:[_entries objectAtIndex:i]];
		
		// write the entry to disk
		[self saveEntry:[_entries objectAtIndex:i]];
		
	}
	
	NSLog(@"Completed reset");
	return YES;
}

- (BOOL) createResourcesForLinkedFiles
{
	// parse each entry for file:// style links and create
	
	BOOL completeSuccess = YES;
	JournlerEntry *anEntry;
	NSEnumerator *enumerator = [[self entries] objectEnumerator];
	
	while ( anEntry = [enumerator nextObject] )
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSMutableAttributedString *mutableContent = [[[anEntry attributedContent] mutableCopyWithZone:[self zone]] autorelease];
		
		NSMutableDictionary *pathToResourceDictionary = [NSMutableDictionary dictionary];
		
		id attr_value;
		NSRange effectiveRange;
		NSRange limitRange = NSMakeRange(0, [mutableContent length]);
		 
		while (limitRange.length > 0)
		{
			attr_value = [mutableContent attribute:NSLinkAttributeName atIndex:limitRange.location 
					longestEffectiveRange:&effectiveRange inRange:limitRange];
			
			if ( attr_value != nil ) 
			{
				NSURL *theURL;
				NSURL *replacementURL = nil;
				
				// make sure we're dealing with a url
				if ( [attr_value isKindOfClass:[NSURL class]] )
					theURL = attr_value;
				else if ( [attr_value isKindOfClass:[NSString class]] )
					theURL = [NSURL URLWithString:attr_value];
				
				// check for a file url
				if ( [theURL isFileURL] )
				{
					// fist see if this filepath has already yielded a resource
					JournlerResource *theResource = [pathToResourceDictionary objectForKey:theURL];
					if ( theResource != nil )
					{
						// easy, the replacement url is the resource uri rep
						replacementURL = [theResource URIRepresentation];
					}
					else
					{
						// produce a file resource for this object, forcing a link
						theResource = [anEntry resourceForFile:[theURL path] operation:kNewResourceForceLink];
						if ( theResource == nil )
						{
							completeSuccess = NO;
							NSLog(@"%@ %s - unable to produce new resource for entry %@ with path %@",
									[self className], _cmd, [anEntry tagID], [theURL path]);
						}
						else
						{
							// easy, the replacement url is the resource uri rep
							replacementURL = [theResource URIRepresentation];
							[pathToResourceDictionary setObject:theResource forKey:theURL];
							
							#ifdef __DEBUG__
							NSLog(@"%@ -> %@", [theURL absoluteString], [replacementURL absoluteString]);
							#endif
						}
					}
					
					// and finally, set the replacement url in place of the current url
					if ( replacementURL != nil )
						[mutableContent addAttribute:NSLinkAttributeName value:replacementURL range:effectiveRange];
				}
			}
			
			limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
		}
		
		[anEntry setValue:mutableContent forKey:@"attributedContent"];
		[pool release];
	}
	
	return ( [self save:nil] && completeSuccess );
}

- (BOOL) updateJournlerResourceTitles
{
	// looks at the available resources and updates their titles to match the titles of the entries they represent
	NSPredicate *typePredicate = [NSPredicate predicateWithFormat:@"type == %i", kResourceTypeJournlerObject];
	NSArray *filteredResources = [[self resources] filteredArrayUsingPredicate:typePredicate];
	
	JournlerResource *aResource;
	NSEnumerator *enumerator = [filteredResources objectEnumerator];
	
	while ( aResource = [enumerator nextObject] )
	{
		JournlerEntry *representedEntry = [aResource journlerObject];
		if ( representedEntry == nil )
		{
			NSLog(@"%@ %s - unable to produce entry for uri %@", [self className], _cmd, [aResource uriString]);
			continue;
		}
		
		[aResource setValue:[representedEntry valueForKey:@"title"] forKey:@"title"];
	}
	
	return [self save:nil];
}

- (BOOL) resetResourceText
{
	JournlerResource *aResource;
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	
	while ( aResource = [enumerator nextObject] )
		[aResource _deriveTextRepresentation:nil];
	
	return [self save:nil];
}

- (BOOL) resetRelativePaths
{
	BOOL completeSucces = YES;
	JournlerResource *aResource;
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	
	while ( aResource = [enumerator nextObject] )
	{
		if ( ![aResource representsFile] )
			continue;
		
		NSString *originalPath = [aResource originalPath];
		if ( originalPath != nil )
		{
			NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:originalPath traverseLink:YES];
			
			[aResource setValue:[fileAttributes objectForKey:NSFileModificationDate] forKey:@"underlyingModificationDate"];
			[aResource setValue:[originalPath stringByAbbreviatingWithTildeInPath] forKey:@"relativePath"];
		}
		else
		{
			completeSucces = NO;
			NSLog(@"%@ %s - original file missing for resource %@-%@ %@", [self className], _cmd, 
			[[aResource entry] tagID], [aResource tagID], [aResource title]);
		}
	}
	
	return ( [self save:nil] && completeSucces );
}

- (NSArray*) orphanedResources
{
	// returns an array of resources that don't have any owner
	NSMutableArray *orphanedResources = [NSMutableArray array];
	NSEnumerator *enumerator = [[self resources] objectEnumerator];
	JournlerResource *aResource;
	
	while ( aResource = [enumerator nextObject] )
	{
		if ( [aResource entry] == nil )
			[orphanedResources addObject:aResource];
		
		if ( [aResource entry] == nil && [[aResource entries] count] > 0 )
			NSLog(@"%@ %s - resource %@:%@ does not have an owner but does belong to entries", [self className], _cmd, [aResource tagID], [aResource title]);
	}
	
	return orphanedResources;
}

- (BOOL) deleteOrphanedResources:(NSArray*)theResources
{
	BOOL completeSuccess = YES;
	JournlerResource *aResource;
	NSEnumerator *enumerator = ( theResources != nil ? [theResources objectEnumerator] : [[self orphanedResources] objectEnumerator] );
	
	while ( aResource = [enumerator nextObject] )
	{
		BOOL localSuccess = [self deleteResource:aResource];
		completeSuccess = ( completeSuccess && localSuccess );
	}
	
	return completeSuccess;
}

@end

#pragma mark -

@implementation JournlerJournal (JournlerScripting)

- (id) owner 
{ 
	return _owner; 
}

- (void) setOwner:(id)owningObject 
{
	_owner = owningObject;
}

@end
