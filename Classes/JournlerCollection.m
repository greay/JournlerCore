//
//  JournlerCollection.m
//  JournlerCore
//
//  Created by Philip Dow on 08.08.05.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <JournlerCore/JournlerCollection.h>
#import <JournlerCore/JournlerEntry.h>
#import <JournlerCore/JournlerJournal.h>
#import <JournlerCore/JournlerCondition.h>

#import <JournlerCore/JournlerSingletons.h>
#import <JournlerCore/Definitions.h>

#import <SproutedUtilities/SproutedUtilities.h>

static NSArray *CollectionKeys() {
	static NSArray *array = nil;
	if (!array) {
		array = [[NSArray alloc] initWithObjects:
			PDCollectionTag,			PDCollectionTitle,
			/*PDCollectionPreds,*/			/*PDCollectionComb,*/			
			PDCollectionTypeID,			PDCollectionParentID,		PDCollectionEntryIDs,
			/*PDCollectionImage,*/			PDCollectionVersion,
			PDJournalIdentifier,		PDCollectionChildrenIDs,	PDCollectionIndex, 
			PDCollectionSortDescriptors, /*PDCollectionLabel,*/ /*PDCollectionEntryTableState,*/ nil];
	}
	return array;
}

static NSArray *CollectionValues() {
	static NSArray *array = nil;
	if (!array) {
		array = [[NSArray alloc] initWithObjects:
			[NSNumber numberWithInt:-1],							// tag
			[NSString stringWithString:@"New Collection"],			// title
			/*[NSArray array],*/										// predicates
			/*[NSNumber numberWithInt:0],*/								// combination rule
			[NSNumber numberWithInt:PDCollectionTypeIDFolder],		// typeID	-- 1.2
			[NSNumber numberWithInt:-1],							// parentID	-- 1.1
			[NSArray array],										// entry ids
			/*[NSImage imageNamed:@"FolderRegular.png"],				// large image */
			[NSNumber numberWithInt:1],								// version number
			[NSNumber numberWithDouble:0],							// journler id
			[NSArray array],										// childen ids
			[NSNumber numberWithInt:0],								// location in parent collection
			[NSArray array],										// sort descriptors
			/*[NSNumber numberWithInt:0],*/								// label
			/*[NSArray array],*/										// entry table state
			nil];
			
		// note the entries, children and the actual parent will be constructed after loading
		// they must be removed before the collection is archived
	}
	return array;
}

static NSImage * DefaultImageForFolderType(NSNumber *type)
{
	static NSString *kLocGenericFolderIcons = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns";
	static NSString *kLocSmartFolderIconsOld = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SmartFolderIcon.icns";
	static NSString *kLocSmartFolderIcons = @"/System/Library/CoreServices/Finder.app/Contents/Resources/SmartFolder.icns";
	static NSString *kLocTrashIcons = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/TrashIcon.icns";
	
	static NSDictionary *imageDictionary = nil;
	if ( imageDictionary == nil )
	{
		NSImage *icon;
		NSMutableDictionary *theImageDictionary = [NSMutableDictionary dictionary];
		
		// the library
		icon = [[NSImage imageNamed:@"NSApplicationIcon"] imageWithWidth:128 height:128 inset:9];
		[theImageDictionary setObject:icon forKey:[NSNumber numberWithInt:PDCollectionTypeIDLibrary]];
		
		
		// regular folder
		icon = [[[NSImage alloc] initWithContentsOfFile:kLocGenericFolderIcons] autorelease];
		// @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Blue_GenericFolder.icns"] autorelease]; -- 10.5?
		if ( icon == nil ) 
		{
			NSLog(@"10.4 DefaultImageForFolderType() - unable to locate GenericFolderIcon");
			icon = [NSImage imageNamed:@"FolderRegular.png"];
		}
			
		icon = [icon imageWithWidth:128 height:128 inset:9];
		[theImageDictionary setObject:icon forKey:[NSNumber numberWithInt:PDCollectionTypeIDFolder]];
		
		
		// the trash
		icon = [[[NSImage alloc] initWithContentsOfFile:kLocTrashIcons] autorelease];
		if ( icon == nil ) 
		{
			NSLog(@"DefaultImageForFolderType() - unable to locate TrashIcon");
			icon = [NSImage imageNamed:@"FolderTrash.png"];
		}
		
		icon = [icon imageWithWidth:128 height:128 inset:9];
		[theImageDictionary setObject:icon forKey:[NSNumber numberWithInt:PDCollectionTypeIDTrash]];
		
		
		// smart folder
		icon = [[[NSImage alloc] initWithContentsOfFile:kLocSmartFolderIcons] autorelease];
		if ( icon == nil ) icon = [[[NSImage alloc] initWithContentsOfFile:kLocSmartFolderIconsOld] autorelease];
		if ( icon == nil ) 
		{
			NSLog(@"10.4 DefaultImageForFolderType() - unable to locate SmartFolderIcon");
			icon = [NSImage imageNamed:@"FolderSmart.png"];
		}
		
		icon = [icon imageWithWidth:128 height:128 inset:9];
		[theImageDictionary setObject:icon forKey:[NSNumber numberWithInt:PDCollectionTypeIDSmart]];
	
		// copy this all to the permanent dictionary
		imageDictionary = [theImageDictionary copyWithZone:[theImageDictionary zone]];
	}
	
	return [imageDictionary objectForKey:type];
}

#pragma mark -

@implementation JournlerCollection

- (id) init 
{
	return [self initWithProperties:nil];
}

- (id) initWithProperties:(NSDictionary*)aDictionary
{
	if ( self = [super initWithProperties:aDictionary] )
	{
		// determine my icon style
		//[self determineIcon];
		
		// initial empty relationships
		parent = nil;
		entries = [[NSMutableArray alloc] init];
		children = [[NSMutableArray alloc] init];
		
		// dynamic predicates
		dynamicDatePredicates = [[NSMutableDictionary alloc] init];
		
		// the entries lock (unused at this point)
		entriesLock = [[NSLock alloc] init];
	}
	return self;
}

+ (NSDictionary*) defaultProperties
{
	NSDictionary *defaults = [NSDictionary dictionaryWithObjects:CollectionValues() forKeys:CollectionKeys()];
	return defaults;
}

+ (JournlerCollection*) separatorFolder
{
	JournlerCollection *aCollection = [[[JournlerCollection alloc] init] autorelease];
	[aCollection setTypeID:[NSNumber numberWithInt:PDCollectionTypeIDSeparator]];
	return aCollection;
}

- (id)copyWithZone:(NSZone *)zone 
{	
	[entriesLock lock];
	
	JournlerCollection *newObject = [[[self class] allocWithZone:zone] init];
	
	[newObject setProperties:[self properties]];
	[newObject setScriptContainer:[self scriptContainer]];
	[newObject setJournal:[self journal]];
	[newObject setEntries:[self entries]];
	[newObject setParent:[self parent]];

	[self deepCopyChildrenToFolder:newObject];
	
	[newObject setDirty:[self dirty]];
	[newObject setDeleted:[self deleted]];
	
	// tag and journal
	[newObject setValue:[NSNumber numberWithInt:[[self journal] newFolderTag]] forKey:@"tagID"];
	[[self journal] addCollection:newObject];
	
	[entriesLock unlock];
	
	return newObject;
}

#pragma mark -

- (void) dealloc 
{		
	[entries release], entries = nil;
	[children release], children = nil;
	
	[entriesLock release], entriesLock = nil;
	[_actualPredicate release], _actualPredicate = nil;
	[dynamicDatePredicates release], dynamicDatePredicates = nil;
	
	// parent is a weak reference, do not dealloc
	
	[super dealloc];
}

#pragma mark -
#pragma mark children

- (NSArray*) children { 
	return children; 
}

- (void) setChildren: (NSArray*)anArray {
	if ( children != anArray )
	{
		[children release];
		children = [anArray mutableCopyWithZone:[self zone]];
		
		// set the children's owner
		[children makeObjectsPerformSelector:@selector(setScriptContainer:) withObject:[[self journal] owner]];
		
		// children's parent
		[children setValue:self forKey:@"parent"];
		
		//[self setDirty:BooleanNumber(YES)];
	}
}

#pragma mark -

- (NSUInteger)countOfChildren {
	return [children count];
}

- (id)objectInChildrenAtIndex:(NSUInteger)theIndex {
	return [children objectAtIndex:theIndex];
}

- (void)getChildren:(id *)objsPtr range:(NSRange)range {
	[children getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inChildrenAtIndex:(NSUInteger)theIndex {
	[children insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)theIndex {
	[children removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInChildrenAtIndex:(NSUInteger)theIndex withObject:(id)obj {
	[children replaceObjectAtIndex:theIndex withObject:obj];
}

#pragma mark -
#pragma mark entries

- (NSArray*) entries  { 
	return entries;
}

- (void) setEntries:(NSArray*)anArray {
	if ( entries != anArray )
	{
		[entries release];
		entries = [anArray mutableCopyWithZone:[self zone]];
		
		//[self setDirty:BooleanNumber(YES)];
	}
}

#pragma mark -

- (NSUInteger)countOfEntries {
	return [entries count];
}

- (id)objectInEntriesAtIndex:(NSUInteger)theIndex {
	return [entries objectAtIndex:theIndex];
}

- (void)getEntries:(id *)objsPtr range:(NSRange)range {
	[entries getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inEntriesAtIndex:(NSUInteger)theIndex {
	[entries insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromEntriesAtIndex:(NSUInteger)theIndex {
	[entries removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInEntriesAtIndex:(NSUInteger)theIndex withObject:(id)obj {
	[entries replaceObjectAtIndex:theIndex withObject:obj];
}

#pragma mark -

- (NSArray*) keyPathsAffectingDirty {
	static NSArray *keyPaths = nil;
	if ( keyPaths == nil ) {
		keyPaths = [[NSArray alloc] initWithObjects:
				@"children", 
				@"entries", nil];
	}
	return keyPaths;
}

#pragma mark -

- (JournlerCollection*)parent 
{ 
	return parent; 
}

- (void ) setParent:(JournlerCollection*)aCollection {
	if ( parent != aCollection ) {
		parent = aCollection;
		
		// invalidate the actual predicate
		[self invalidatePredicate:YES];
	
		[self setDirty:BooleanNumber(YES)];
	}
}

#pragma mark -
#pragma mark Set Requirements

- (BOOL)isEqual:(id)anObject 
{
	// tests for the class and then the NSInteger tag id
	return ( [anObject isMemberOfClass:[self class]] && [[self tagID] intValue] == [[anObject tagID] intValue] );
}

#pragma mark -
#pragma mark coder requirements

- (id)initWithCoder:(NSCoder *)decoder 
{	
	if ( self = [self init] ) 
	{
		//empty values <- in order to avoid nil errors, backwards compatiblity
		NSDictionary *archivedProperties = [decoder decodeObjectForKey:@"JCollProperties"];
		if ( !archivedProperties ) {
			return nil;
			// error
		}
		
		//
		// leave it to the dictionary to convert:
		//	a) parentID -> parent
		//	b) childrenIDs -> children
		//	c) entryIDs -> entries
		
				
		// add the archived properties to the empty dictionary
		// and thus backwards compatibility is maintained while ensuring that user attributes are preserved
		[_properties addEntriesFromDictionary:archivedProperties];
	}
	
	return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder {
	
	NSInteger i;	
	//
	// go through the dictionary and set all of our keys to the coder
	//
	
	if ( ![encoder allowsKeyedCoding] ) {
		NSLog(@"Cannot encode Journler Collection without a keyed archiver");
		return;
	}
	
	[entriesLock lock];
	
	//
	// convert the parent to a parent id
	if ( [self parent] ) [self setParentID:[[self parent] tagID]];
	// -------------------------------------
	
	//
	// convert the children to children ids
	NSArray *theChildren = [self children];
	if ( theChildren ) {
		NSMutableArray *childrenIDs = [[[NSMutableArray alloc] initWithCapacity:[theChildren count]] autorelease];
		
		for ( i = 0; i < [theChildren count]; i++ )
			[childrenIDs addObject:[[theChildren objectAtIndex:i] tagID]];
		
		[self setChildrenIDs:childrenIDs];
	}
	// -------------------------------------
	
	//
	// convert the entries to entry ids
	NSArray *theEntries = [self entries];
	if ( theEntries != nil ) {
		NSMutableArray *entryIDs = [[NSMutableArray alloc] initWithCapacity:[theEntries count]];
		
		for ( i = 0; i < [theEntries count]; i++ )
			[entryIDs addObject:[[theEntries objectAtIndex:i] tagID]];
		
		[self setEntryIDs:entryIDs];
		[entryIDs release];
	}
	// -------------------------------------
	
	//
	// grab a mutable copy of the dictionary
	NSMutableDictionary *toEncode = [[self properties] mutableCopyWithZone:[self zone]];
	
	//
	// remove the parent, children and entries from it - only their ids are coded
	[toEncode removeObjectsForKeys:[NSArray arrayWithObjects:
			PDCollectionParent, PDCollectionChildren, 
			PDCollectionEntries, nil]];
	
	// remove the icon if it's the default icon
	if ( [_properties objectForKey:PDCollectionImage] == [JournlerCollection defaultImageForID:[[self typeID] intValue]] )
		[toEncode removeObjectForKey:PDCollectionImage];
			
	[encoder encodeObject:toEncode forKey:@"JCollProperties"];
	
	//
	// clean up
	[toEncode release];
	
	[entriesLock unlock];
	
}

#pragma mark -

- (void) addEntry:(JournlerEntry*)entry 
{
	[entriesLock lock];
	
	// no need to add if we already have it
	if ( [[self entries] indexOfObjectIdenticalTo:entry] != NSNotFound )
	{
		[entriesLock unlock];
		return;
	}
	
	// do not add the entry if it is marked for the trash, unless we're the trash
	if ( [[entry valueForKey:@"markedForTrash"] boolValue] && [[self valueForKey:@"typeID"] intValue] != PDCollectionTypeIDTrash )
	{
		[entriesLock unlock];
		return;
	}
	
	// add the entry to my enty list
	[[self mutableArrayValueForKey:@"entries"] addObject:entry];
	
	// add myself to the entry's collection list, but not if I'm the library or the trash
	if ( [[self valueForKey:@"typeID"] intValue] != PDCollectionTypeIDLibrary 
			&& [[self valueForKey:@"typeID"] intValue] != PDCollectionTypeIDTrash )
		[[entry mutableArrayValueForKey:@"collections"] addObject:self];
		
	// post the notification -- used in the folderscontroller to update the entry count
	// could I accomplish the same with kvo?
	#warning end folderdidadd and remove notifications, use kvo in folderscontroller
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:FolderDidAddEntryNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"] 
			waitUntilDone:YES];
			
	[entriesLock unlock];
}

#pragma mark -

- (BOOL) evaluateAndAct:(id)object 
{
	BOOL adds = NO;
	NSArray *allEntries = nil;
	
	if ( [object isKindOfClass:[JournlerEntry class]] )
		allEntries = [NSArray arrayWithObject:object];
	else if ( [object isKindOfClass:[NSArray class]] )
		allEntries = object;
	else
		return NO;
	
	NSDictionary *evalDict = [NSDictionary dictionaryWithObjectsAndKeys:
			allEntries, @"entries", 
			[NSNumber numberWithBool:NO], @"recursive", nil];
	
	[self _threadedEvaluateAndAct:evalDict];
	return adds;
}

// I WANT TO DEPRECATE THIS
- (BOOL) evaluateAndAct:(id)object considerChildren:(BOOL)recursive 
{
	// return value does not suggest actual results
	
	// composes the predicate values, tests the object, 
	// and removes or adds as necessary - including recursion for children
	
	BOOL adds = NO;
	NSArray *allEntries = nil;
	
	if ( [object isKindOfClass:[JournlerEntry class]] )
		allEntries = [NSArray arrayWithObject:object];
	else if ( [object isKindOfClass:[NSArray class]] )
		allEntries = object;
	else
		return NO;
	
	NSDictionary *evalDict = [NSDictionary dictionaryWithObjectsAndKeys:
			allEntries, @"entries", 
			[NSNumber numberWithBool:recursive], @"recursive", nil];
	
	[self _threadedEvaluateAndAct:evalDict];
	return adds;
}

- (void) _threadedEvaluateAndAct:(NSDictionary*)evalDict
{
	BOOL adds;
	
	[entriesLock lock];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self setIsEvaluating:YES];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:FolderWillBeginEvaluation 
			object:self 
			userInfo:nil 
			waitUntilDone:YES];
	
	NSArray *underEvaluation = [evalDict objectForKey:@"entries"];
	BOOL recursive = [[evalDict objectForKey:@"recursive"] boolValue];
	
	if ( [self isSmartFolder] )
	{
		// grab the predicate
		NSPredicate *smartPredicate = [self effectivePredicate];
		if ( smartPredicate != nil )
		{
			NSInteger i;
			for ( i = 0; i < [underEvaluation count]; i++ ) 
			{
				JournlerEntry *entry = [underEvaluation objectAtIndex:i];
				
				// evalute the entry against this predicate
				if ( [smartPredicate evaluateWithObject:entry] ) 
				{
					// do not add if the entry is marked for the trash or if the entry is already part of this folder
					// arrays aren't sets, and we only want a single instance of the entry in the collection
					if ( [[entry valueForKey:@"markedForTrash"] boolValue] 
							|| [[self valueForKey:@"entries"] indexOfObjectIdenticalTo:entry] != NSNotFound )
						continue;
						
					// add the entry to my enty list
					[[self mutableArrayValueForKey:@"entries"] addObject:entry];
					[[entry mutableArrayValueForKey:@"collections"] addObject:self];
				}
				else 
				{
					// remove the entry from my list
					[[self mutableArrayValueForKey:@"entries"] removeObject:entry];
					[[entry mutableArrayValueForKey:@"collections"] removeObject:self];
				}
			}
			
			#warning what aboue kvo-notifications on a separate thread?
			// set our entries
			//[self setValue:myEntries forKey:@"entries"];
			// is this causing the problem?
			//[self performSelectorOnMainThread:@selector(setEntries:) 
			//		withObject:myEntries 
			//		waitUntilDone:YES];
		}
	}
	
	if ( recursive ) 
	{
		// pass the entry on to the children
		NSInteger i;
		NSArray *theChildren = [self children];

		if ( theChildren != nil ) 
		{
			for ( i = 0; i < [theChildren count]; i++ )
			{
				BOOL thisAdd = [[theChildren objectAtIndex:i] evaluateAndAct:underEvaluation considerChildren:YES];
				adds = ( thisAdd || adds );
			}
		}
	}
	
	[self setIsEvaluating:NO];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:FolderDidCompleteEvaluation 
			object:self 
			userInfo:nil 
			waitUntilDone:YES];
	
	[pool release];
	[entriesLock unlock];
}

- (void) removeEntry:(JournlerEntry*)entry 
{	
	[entriesLock lock];
	
	// no need to remove if it's already not there
	if ( [[self entries] indexOfObjectIdenticalTo:entry] == NSNotFound )
	{
		[entriesLock unlock];
		return;
	}
	
	// remove the entry from my list
	[[self mutableArrayValueForKey:@"entries"] removeObject:entry];
	
	// remove myself from the entry's collection list
	if ( [[self valueForKey:@"typeID"] intValue] != PDCollectionTypeIDLibrary 
			&& [[self valueForKey:@"typeID"] intValue] != PDCollectionTypeIDTrash )
		[[entry mutableArrayValueForKey:@"collections"] removeObject:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:FolderDidRemoveEntryNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:entry forKey:@"entry"] 
			waitUntilDone:YES];
	
	[entriesLock unlock];
}

// I WANT TO DEPRECATE THIS FUNCTION
- (void) removeEntry:(JournlerEntry*)entry considerChildren:(BOOL)recursive 
{
	[self removeEntry:entry];
		
	if ( recursive ) 
	{
		// perform the same operation on the children
		NSInteger i;
		NSArray *theChildren = [self children];

		if ( theChildren != nil ) 
		{
			for ( i = 0; i < [theChildren count]; i++ )
				[[theChildren objectAtIndex:i] removeEntry:entry considerChildren:recursive];
		}
	}	
}

#pragma mark -

- (BOOL) isEvaluating {
	return isEvaluating;
}

- (void) setIsEvaluating:(BOOL)evaluating {
	isEvaluating = evaluating;
}

#pragma mark -
#pragma mark JournlerObject overrides

+ (NSString*) tagIDKey {
	return PDCollectionTag;
}

+ (NSString*) titleKey {
	return PDCollectionTitle;
}

+ (NSString*) iconKey {
	return PDCollectionImage;
}

#pragma mark -

- (NSNumber*) typeID {
	return [_properties objectForKey:PDCollectionTypeID]; 
}

- (void) setTypeID:(NSNumber*)newType {
	[_properties setObject:(newType?newType:[NSNumber numberWithInt:PDCollectionTypeIDFolder]) forKey:PDCollectionTypeID];
	[self setDirty:BooleanNumber(YES)];
}

- (NSNumber*) version { 
	return [_properties objectForKey:PDCollectionVersion]; 
} 

- (void) setVersion:(NSNumber*)newVersion {
	[_properties setObject:(newVersion?newVersion:[NSNumber numberWithInt:1]) forKey:PDCollectionVersion];
	[self setDirty:BooleanNumber(YES)];
}

- (NSArray*) conditions { 
	NSArray *conditions = [_properties objectForKey:PDCollectionPreds];
	if ( conditions == nil ) conditions = EmptyArray();
	return conditions;
}

- (void) setConditions:(NSArray*)newPredicates {
	[_properties setObject:(newPredicates?newPredicates:[NSArray array]) forKey:PDCollectionPreds];
	
	// invalidate the actual predicate
	[self invalidatePredicate:YES];
	
	[self setDirty:BooleanNumber(YES)];
}

#pragma mark -

- (NSNumber*) combinationStyle { 
	return [_properties objectForKey:PDCollectionComb]; 
}

- (void) setCombinationStyle:(NSNumber*)newStyle {
	[_properties setObject:(newStyle?newStyle:[NSNumber numberWithInt:0]) forKey:PDCollectionComb];
	
	// invalidate the actual predicate
	[self invalidatePredicate:YES];
	
	[self setDirty:BooleanNumber(YES)];
}

- (NSArray*) sortDescriptors { 
	return [_properties objectForKey:PDCollectionSortDescriptors]; 
}

- (void) setSortDescriptors:(NSArray*)anArray {
	[_properties setObject:(anArray?anArray:[NSArray array]) forKey:PDCollectionSortDescriptors];
	[self setDirty:BooleanNumber(YES)];
}

- (NSNumber*) label  { 
	NSNumber *theLabel = [_properties objectForKey:PDCollectionLabel];
	if ( theLabel == nil ) theLabel = ZeroNumber();
	return theLabel;
}

- (void) setLabel:(NSNumber*)aNumber {
	[_properties setObject:(aNumber?aNumber:[NSNumber numberWithInt:0]) forKey:PDCollectionLabel];
	[self setDirty:BooleanNumber(YES)];
	
	// post a notification that this attribute has changed
	[[NSNotificationCenter defaultCenter] postNotificationName:JournlerObjectDidChangeValueForKeyNotification 
			object:self 
			userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
					JournlerObjectAttributeLabelKey, JournlerObjectAttributeKey, nil]];
}

- (NSImage*) icon {
	NSImage *theIcon = [_properties objectForKey:PDCollectionImage];
	if ( theIcon == nil ) theIcon = [self determineIcon];
	return theIcon;
}

- (void) setIcon:(NSImage*)anImage {
	[super setIcon:anImage];
	[self setDirty:BooleanNumber(YES)];
}

#pragma mark -

- (NSNumber*) index { 
	return [_properties objectForKey:PDCollectionIndex]; 
}

- (void) setIndex:(NSNumber*)index {
	[_properties setObject:(index?index:[NSNumber numberWithInt:0]) forKey:PDCollectionIndex];
	[self setDirty:BooleanNumber(YES)];
}


#pragma mark -

- (NSArray*) entryIDs { 
	return [_properties objectForKey:PDCollectionEntryIDs];
}

- (void) setEntryIDs:(NSArray*)anArray {
	[_properties setObject:(anArray?anArray:[NSArray array]) forKey:PDCollectionEntryIDs];
}

- (NSMutableArray*) childrenIDs { 
	return [_properties objectForKey:PDCollectionChildrenIDs]; 
}

- (void) setChildrenIDs: (NSArray*)theChildren {
	[_properties setObject:(theChildren?theChildren:[NSArray array]) forKey:PDCollectionChildrenIDs];
}

- (NSNumber*) parentID { 
	return [_properties objectForKey:PDCollectionParentID]; 
}

- (void) setParentID:(NSNumber*)theParent {
	[_properties setObject:(theParent?theParent:[NSNumber numberWithInt:-1]) forKey:PDCollectionParentID];
}

#pragma mark -

- (NSURL*) URIRepresentation
{	
	NSString *urlString = [NSString stringWithFormat:@"journler://folder/%@", [self valueForKey:@"tagID"]];
	if ( urlString == nil )
	{
		NSLog(@"%@ %s - unable to create string representation of entry #%@", [self className], _cmd, [self valueForKey:@"tagID"]);
		return nil;
	}
	
	NSURL *url = [NSURL URLWithString:urlString];
	if ( url == nil )
	{
		NSLog(@"%@ %s - unable to create url representation of entry #%@", [self className], _cmd, [self valueForKey:@"tagID"]);
		return nil;
	}
	
	return url;
}


#pragma mark -

+ (NSImage*) defaultImageForID:(NSInteger)type 
{
	// utility method to set the folder's icons	
	NSImage *icon = nil;
	
	switch ( type )
	{
	
	case PDCollectionTypeIDLibrary:
	case PDCollectionTypeIDTrash:
	case PDCollectionTypeIDFolder:
	case PDCollectionTypeIDSmart:
		
		icon = DefaultImageForFolderType([NSNumber numberWithInt:type]);
		break;
		
	case PDCollectionTypeIDWebArchive:
		
		icon = [[[NSImage alloc] 
				initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SitesFolderIcon.icns"] autorelease];
		if ( icon == nil ) 
		{
			NSLog(@"%@ %s - unable to locate SitesFolderIcon", [self className], _cmd);
			icon = [NSImage imageNamed:@"FolderWebarchives.png"];
		}
		
		icon = [icon imageWithWidth:128 height:128 inset:9];
		break;
	
	case PDCollectionTypeIDAudio:
		
		icon = [[[NSImage alloc] 
				initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/MusicFolderIcon.icns"] autorelease];
		if ( icon == nil ) 
		{
			NSLog(@"%@ %s - unable to locate MusicFolderIcon", [self className], _cmd);
			icon = [NSImage imageNamed:@"FolderMusic.png"];
		}
		
		icon = [icon imageWithWidth:128 height:128 inset:9];
		break;
	
	case PDCollectionTypeIDVideo:
		
		icon = [[[NSImage alloc] 
				initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/MovieFolderIcon.icns"] autorelease];
		if ( icon == nil ) 
		{
			NSLog(@"%@ %s - unable to locate MovieFolderIcon", [self className], _cmd);
			icon = [NSImage imageNamed:@"FolderMovies.png"];
		}
		
		icon = [icon imageWithWidth:128 height:128 inset:9];
		break;
	
	case PDCollectionTypeIDImage:
		
		icon = [[[NSImage alloc] 
				initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/PicturesFolderIcon.icns"] autorelease];
		if ( icon == nil ) 
		{
			NSLog(@"%@ %s - unable to locate PicturesFolderIcon", [self className], _cmd);
			icon = [NSImage imageNamed:@"FolderImages.png"];
		}
		
		icon = [icon imageWithWidth:128 height:128 inset:9];
		break;
	
	case PDCollectionTypeIDDocuments:
		
		icon = [[[NSImage alloc] 
				initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/DocumentsFolderIcon.icns"] autorelease];
		if ( icon == nil ) 
		{
			NSLog(@"%@ %s - unable to locate DocumentsFolderIcon", [self className], _cmd);
			icon = [NSImage imageNamed:@"FolderDocuments.png"];
		}
		
		icon = [icon imageWithWidth:128 height:128 inset:9];
		break;
	
	case PDCollectionTypeIDPDF:
		
		icon = [NSImage imageNamed:@"FolderPDFs.png"];
		icon = [icon imageWithWidth:128 height:128 inset:9];
		
		break;
	
	case PDCollectionTypeIDBookmark:
		
		icon = [NSImage imageNamed:@"FolderBookmarks.png"];
		icon = [icon imageWithWidth:128 height:128 inset:9];
		
		break;
	}
	
	return icon;
}

- (NSImage*) determineIcon 
{
	NSImage *theIcon = [JournlerCollection defaultImageForID:[[self typeID] intValue]];
	[self setValue:theIcon forKey:@"icon"];
	return theIcon;
}

#pragma mark -

- (void) addChild:(JournlerCollection*)subfolder atIndex:(NSUInteger)index 
{	
	// check to make sure the index is not over or that we want the item to be last
	if ( index == -1 || index > [self countOfChildren] ) 
		index = [self countOfChildren];
	
	// set the folder's script container
	[subfolder setScriptContainer:[[self journal] owner]];
	
	// set the parent
	[subfolder setParent:self];
	[subfolder setParentID:[self tagID]];

	// insert the child at the index
	[subfolder setValue:[NSNumber numberWithInt:index] forKey:@"index"];
	
	//[tempChildren insertObject:n atIndex:index];
	[[self mutableArrayValueForKey:@"children"] insertObject:subfolder atIndex:index];
	
	// all the children this and after must have their index values adjusted
	NSInteger i;
	for ( i = index; i < [self countOfChildren]; i++ )
		[[self objectInChildrenAtIndex:i] setValue:[NSNumber numberWithInt:i] forKey:@"index"];
}

- (void)removeChild:(JournlerCollection *)subfolder recursively:(BOOL)recursive 
{
	[subfolder retain];
	
	if ( recursive ) 
	{
		// also remove the n object's children
		NSInteger i;
		for ( i = 0; i < [subfolder countOfChildren]; i++ )
			[subfolder removeChild:[[subfolder children] objectAtIndex:i] recursively:YES];
	}
	
	NSInteger old_index = [[self children] indexOfObjectIdenticalTo:subfolder];
	[[self mutableArrayValueForKey:@"children"] removeObject:subfolder];
		
	// all the children this and after must have their index values adjusted
	NSInteger i;
	for ( i = old_index; i < [self countOfChildren]; i++ )
		[[self objectInChildrenAtIndex:i] setValue:[NSNumber numberWithInt:i] forKey:@"index"];
	
	[subfolder release];
}

- (void) moveChild:(JournlerCollection *)aFolder toIndex:(NSUInteger)anIndex
{
	if ( anIndex > [[aFolder valueForKey:@"index"] intValue] )
		anIndex--;
	
	[aFolder retain];
	[self removeChild:aFolder recursively:NO];
	[self addChild:aFolder atIndex:anIndex];
	[aFolder release];
}

#pragma mark -

- (NSArray*) allChildren 
{
	// returns all of the children contained in this collection in no particular order
	NSInteger i;
	NSArray *kids = [[[self children] copyWithZone:[self zone]] autorelease];
	NSMutableArray *returnArray = [[[NSMutableArray alloc] init] autorelease];
	
	for ( i = 0; i < [kids count]; i++ ) 
	{
		[returnArray addObject:[kids objectAtIndex:i]];
		[returnArray addObjectsFromArray:[[kids objectAtIndex:i] allChildren]];
	}

	return returnArray;
}


#pragma mark -
#pragma mark Utilities

//
// backwards compatability, deprecated

- (NSString*) pureType 
{ 
	// used by the upgrade controller
	return [_properties objectForKey:PDCollectionType]; 
}

- (void) clearOldProperties 
{	
	// used by the upgrade controller
	[_properties removeObjectsForKeys:[NSArray arrayWithObjects:
			PDCollectionParent, PDCollectionChildren, 
			PDCollectionEntries, PDCollectionType, nil]];	
}


- (void) deepCopyChildrenToFolder:(JournlerCollection*)aFolder
{
	// used by [JournlerCollection copyWithZone:]
	JournlerCollection *aChildFolder;
	NSEnumerator *enumerator = [[self children] objectEnumerator];
	NSMutableArray *copiedChildren = [NSMutableArray array];
	
	while ( aChildFolder = [enumerator nextObject] )
	{
		JournlerCollection *aNewChildFolder = [[aChildFolder copyWithZone:[self zone]] autorelease];
		[copiedChildren addObject:aNewChildFolder];
	}
	
	[aFolder setChildren:copiedChildren];
}

#pragma mark -

- (void) sortChildrenByIndex 
{
	#warning is sortChildrenByIndex necessary? It's only called at load
	
	// sort the children according to their index values
	NSSortDescriptor *indexSort = [[[NSSortDescriptor alloc] initWithKey:PDCollectionIndex 
			ascending:YES 
			selector:@selector(compare:)] autorelease];
	NSArray *defaultSort = [[NSArray alloc] initWithObjects:indexSort, nil];
			
	NSArray *sortedChildren = [[self children] sortedArrayUsingDescriptors:defaultSort];
	if ( !sortedChildren )
		return;
	
	// sort the children's children
	NSInteger i;
	for ( i = 0; i < [sortedChildren count]; i++ )
		[[sortedChildren objectAtIndex:i] sortChildrenByIndex];
	
	[self setChildren:sortedChildren];
	[defaultSort release];
}

#pragma mark -
#pragma mark Smart Folders: Predicates, Evaluation, Conditions

- (BOOL) generateDynamicDatePredicates:(BOOL)recursive
{	
	// create new predicates for the dynamic date predicates
	
	BOOL madeChanges = NO;
	
	if ( ![self isSmartFolder] )
		return NO;
	
	// clear the dynamic predicates
	[dynamicDatePredicates removeAllObjects];
	
	NSString *aCondition;
	NSEnumerator *conditionEnumerator = [[self conditions] objectEnumerator];
	
	NSInteger dateTag, dateValue;
	NSScanner *theScanner;
	NSString *keyValue;
	NSCalendarDate *today = [NSCalendarDate calendarDate];
	
	NSCharacterSet *digitSet = [NSCharacterSet decimalDigitCharacterSet];
	NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
	
	// go through each condition, looking for "inthelast" or "inthenext" predicates
	while ( aCondition = [conditionEnumerator nextObject] )
	{
		//NSLog(@"%@ %s - condition: %@", [self className], _cmd, aCondition);
		
		if ( [aCondition rangeOfString:@"inthelast" options:NSLiteralSearch range:NSMakeRange(0,[aCondition length])].location != NSNotFound )
		{
			theScanner = [NSScanner scannerWithString:aCondition];
			
			[theScanner scanUpToCharactersFromSet:whitespaceSet intoString:&keyValue];
			[theScanner scanUpToCharactersFromSet:digitSet intoString:nil];
			[theScanner scanInt:&dateTag];
			[theScanner scanUpToCharactersFromSet:digitSet intoString:nil];
			[theScanner scanInt:&dateValue];
			
			NSString *targetString = nil;
			NSString *todayString = [today descriptionWithCalendarFormat:@"%Y%m%d"];
			NSCalendarDate *targetDate = [NSCalendarDate dateWithString:todayString calendarFormat:@"%Y%m%d"];
			
			if ( dateTag == 0 )
				targetString = [[targetDate dateByAddingYears:0 months:0 days:-dateValue hours:0 minutes:0 seconds:0] descriptionWithCalendarFormat:@"%Y%m%d"];
			else if ( dateTag == 1 )
				targetString = [[targetDate dateByAddingYears:0 months:0 days:-dateValue*7 hours:0 minutes:0 seconds:0] descriptionWithCalendarFormat:@"%Y%m%d"];
			else if ( dateTag == 2 )
				targetString = [[targetDate dateByAddingYears:0 months:-dateValue days:0 hours:0 minutes:0 seconds:0] descriptionWithCalendarFormat:@"%Y%m%d"];
					
			NSString *replacementCondition = [NSString stringWithFormat:@"%@ between { %@ , %@ }", keyValue, targetString, todayString];
			[dynamicDatePredicates setObject:replacementCondition forKey:aCondition];
			
			//NSLog(@"%@ %s - set %@ for %@", [self className], _cmd, replacementCondition, aCondition );
			
			madeChanges = YES;
		}
		else if ( [aCondition rangeOfString:@"inthenext" options:NSLiteralSearch range:NSMakeRange(0,[aCondition length])].location != NSNotFound )
		{
			theScanner = [NSScanner scannerWithString:aCondition];
			
			[theScanner scanUpToCharactersFromSet:whitespaceSet intoString:&keyValue];
			[theScanner scanUpToCharactersFromSet:digitSet intoString:nil];
			[theScanner scanInt:&dateTag];
			[theScanner scanUpToCharactersFromSet:digitSet intoString:nil];
			[theScanner scanInt:&dateValue];
			
			NSString *targetString = nil;
			NSString *todayString = [today descriptionWithCalendarFormat:@"%Y%m%d"];
			NSCalendarDate *targetDate = [NSCalendarDate dateWithString:todayString calendarFormat:@"%Y%m%d"];
			
			if ( dateTag == 0 )
				targetString = [[targetDate dateByAddingYears:0 months:0 days:dateValue hours:0 minutes:0 seconds:0] descriptionWithCalendarFormat:@"%Y%m%d"];
			else if ( dateTag == 1 )
				targetString = [[targetDate dateByAddingYears:0 months:0 days:dateValue*7 hours:0 minutes:0 seconds:0] descriptionWithCalendarFormat:@"%Y%m%d"];
			else if ( dateTag == 2 )
				targetString = [[targetDate dateByAddingYears:0 months:dateValue days:0 hours:0 minutes:0 seconds:0] descriptionWithCalendarFormat:@"%Y%m%d"];
					
			NSString *replacementCondition = [NSString stringWithFormat:@"%@ between { %@ , %@ }", keyValue, todayString, targetString];
			[dynamicDatePredicates setObject:replacementCondition forKey:aCondition];
			
			//NSLog(@"%@ %s - set %@ for %@", [self className], _cmd, replacementCondition, aCondition );
			
			madeChanges = YES;
		}
	}
	
	if ( recursive ) 
	{
		NSInteger i;
		NSArray *kids = [self children];

		for ( i = 0; i < [kids count]; i++)
			madeChanges = ( [[kids objectAtIndex:i] generateDynamicDatePredicates:YES] || madeChanges );
	}
	
	//NSLog([dynamicDatePredicates description]);
	return madeChanges;
}

- (void) invalidatePredicate:(BOOL)recursive 
{
	[entriesLock lock];
	
	[_actualPredicate release];
	_actualPredicate = nil;
	
	if ( recursive ) 
	{
		NSInteger i;
		NSArray *kids = [self children];

		for ( i = 0; i < [kids count]; i++)
			[[kids objectAtIndex:i] invalidatePredicate:YES];
	}
	
	[entriesLock unlock];
}

- (NSString*) predicateString 
{
	// builds the predicate string for this node
	
	NSInteger i;
	NSArray *predicates = [self conditions];
	if ( !predicates || [predicates count] == 0 )
		return [NSString string];
	
	NSString *combiWord = ( [[self combinationStyle] intValue] == 0 ? @"or" : @"and" );
	
	// check if the first item is available as a dynamic date predicate
	NSString *firstReplacementPref = [dynamicDatePredicates objectForKey:[predicates objectAtIndex:0]];
	
	// if it is not check to see if the first predicate string needs to be normalized for tags
	if ( firstReplacementPref == nil )
	{
		firstReplacementPref = [predicates objectAtIndex:0];
		if ( [firstReplacementPref rangeOfString:@"in tags" options:NSBackwardsSearch].location == ( [firstReplacementPref length] - 7 ) )
			firstReplacementPref = [JournlerCondition normalizedTagCondition:firstReplacementPref];
	}
	
	NSMutableString *predicateString = [[NSMutableString alloc] 
	initWithFormat:@"( %@ )", ( firstReplacementPref != nil ? firstReplacementPref : [predicates objectAtIndex:0] )];
	
	for ( i = 1; i < [predicates count]; i++ )
	{
		// check the condition for a dynamic dates equivalent
		NSString *replacementPred = [dynamicDatePredicates objectForKey:[predicates objectAtIndex:i]];
		
		// if one does not exist check to see if the first predicate string needs to be normalized for tags
		if ( replacementPred == nil )
		{
			replacementPred = [predicates objectAtIndex:i];
			if ( [replacementPred rangeOfString:@"in tags" options:NSBackwardsSearch].location == ( [replacementPred length] - 7 ) )
				replacementPred = [JournlerCondition normalizedTagCondition:replacementPred];
		}
		
		[predicateString appendFormat:@" %@ ( %@ )", combiWord, ( replacementPred != nil ? replacementPred : [predicates objectAtIndex:i] )];
	}
	
	return [predicateString autorelease];

}

- (NSPredicate*) predicate 
{
	// builds the predicate for this node
	NSPredicate *thePredicate = nil;
	NSString *predicateString = [self predicateString];
	
	if ( [predicateString rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]].location != NSNotFound )
	{
		@try
		{
			// watch for exceptions that simply hang the program
			// build the predicate, release the complete string, return the predicate
			thePredicate = [NSPredicate predicateWithFormat:predicateString];
		}
		@catch (NSException *exception)
		{
			NSLog(@"%@ %s exception encountered while building predicate from string %@, exception %@", 
			[self className], _cmd, predicateString, exception);
		}
	}

	return thePredicate;
}

- (NSPredicate*) effectivePredicate 
{
	// builds the predicate for this node and all parent nodes together	
	if ( _actualPredicate != nil ) return _actualPredicate;
	
	NSPredicate *thePredicate = nil;
	JournlerCollection *aParent = self;
	NSMutableString *completePredicateString = [[[NSMutableString alloc] initWithFormat:@"( %@ )", [self predicateString]] autorelease];
				
	while ( aParent = [aParent parent] ) 
	{
		NSString *predicateFormat;
	
		// break out of the loop if this is the parent
		if ( aParent == nil || [[aParent valueForKey:@"tagID"] intValue] == -1 ) break;
		
		// continue on if this is not a smart folder
		if ( [[aParent valueForKey:@"typeID"] intValue] == PDCollectionTypeIDSmart ) 
		{
			// grab this nodes predicate
			predicateFormat = [aParent predicateString];
			
			// add it to the complete string
			if ( predicateFormat != nil )
				[completePredicateString appendFormat:@" and ( %@ )", predicateFormat];
		}
	}
	
	// only attempt to put the predicate together if it contains alphanumeric characters
	if ( [completePredicateString rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]].location != NSNotFound )
	{
		@try
		{
			// watch for exceptions that simply hang the program
			// build the predicate, release the complete string, return the predicate
			thePredicate = [NSPredicate predicateWithFormat:completePredicateString];
		}
		@catch (NSException *exception)
		{
			NSLog(@"%@ %s exception encountered while building predicate from string %@, exception %@", 
			[self className], _cmd, completePredicateString, exception);
		}
	}
	
	_actualPredicate = [thePredicate copyWithZone:[self zone]];
	return _actualPredicate;
}

#pragma mark -
#pragma mark Autotagging

- (NSArray*) allConditions:(BOOL)grouped
{
	// includes the conditions of this folder and its parent folder
	
	JournlerCollection *aParent = self;
	NSMutableArray *allConditions = [NSMutableArray array];
	
	if ( grouped )
	{
		NSArray *myConditions = [self conditions];
		if ( myConditions != nil )
		{
			NSDictionary *firstDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					myConditions, @"conditions",
					[self combinationStyle], @"combinationStyle", nil];
			[allConditions addObject:firstDictionary];
		}
		
		while ( aParent = [aParent parent] ) 
		{
			// break out of the loop if this is the parent
			if ( aParent == nil || [[aParent valueForKey:@"tagID"] intValue] == -1 ) break;
			
			// continue on if this is not a smart folder
			if ( ![aParent isSmartFolder] ) 
				continue;
			
			NSArray *theConditions = [aParent conditions];
			NSDictionary *aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					theConditions, @"conditions",
					[aParent combinationStyle], @"combinationStyle", nil];
			[allConditions addObject:aDictionary];

		}
					
	}
	else
	{
		// not grouped, I take all the conditions in an array
		[allConditions addObjectsFromArray:[self conditions]];
		
		while ( aParent = [aParent parent] ) 
		{
			// break out of the loop if this is the parent
			if ( aParent == nil || [[aParent valueForKey:@"tagID"] intValue] == -1 ) break;
			
			// continue on if this is not a smart folder
			if ( ![aParent isSmartFolder] ) 
				continue;
			
			[allConditions addObjectsFromArray:[aParent conditions]];
		}
	
	}
	
	return allConditions;
}

- (BOOL) autotagsKey:(NSString*)aKey
{
	if ( ![self isSmartFolder] )
		return NO;
	
	BOOL affects = NO;
	NSString *aCondition;
	NSEnumerator *enumerator = [[self allConditions:NO] objectEnumerator];
	
	while ( aCondition = [enumerator nextObject] )
	{
		if ( [JournlerCondition condition:aCondition affectsKey:aKey] )
		{
			affects = YES;
			break;
		}
	}
	
	return affects;
}

- (BOOL) canAutotag:(JournlerEntry*)anEntry
{
	BOOL canAutotag = YES;
	
	if ( ![self isSmartFolder] )
		return NO;
	
	NSArray *allConditions = [self allConditions:YES];
	NSDictionary *aDictionary;
	NSEnumerator *enumerator = [allConditions objectEnumerator];
	
	// supported conditions:
	// 1. title	2. category	3. keywords 4. label 5. mark
	
	while ( aDictionary = [enumerator nextObject] )
	{
		// get the conditions and the operation
		// if the operation requires every condition met, check for that, otherwise just grab the first
		
		NSString *aCondition;
		NSArray *localConditions = [aDictionary objectForKey:@"conditions"];
		NSEnumerator *localEnumerator = [localConditions objectEnumerator];
		NSNumber *localCombination = [aDictionary objectForKey:@"combinationStyle"];
		
		if ( [localCombination intValue] == 0 )
		{
			// any condition that matches is good enough
			canAutotag = NO;
			
			while ( aCondition = [localEnumerator nextObject] )
			{
				NSDictionary *conditionOp = [JournlerCondition operationForCondition:aCondition entry:anEntry];
				#ifdef __DEBUG__
				NSLog([conditionOp description]); 
				#endif
				
				if ( conditionOp != nil )
				{
					canAutotag = YES;
					break;
				}
			}
			
			// if canAutoTag is still no at this point, go ahead and quit
			if ( canAutotag == NO )
				break;
		}
		
		else if ( [localCombination intValue] == 1 )
		{
			// every condition must match
			while ( aCondition = [localEnumerator nextObject] )
			{
				NSDictionary *conditionOp = [JournlerCondition operationForCondition:aCondition entry:anEntry];
				#ifdef __DEBUG__
				NSLog([conditionOp description]); 
				#endif
				
				if ( conditionOp == nil )
				{
					canAutotag = NO;
					break;
				}
			}

		}
		
		/*
		NSDictionary *conditionOp = [JournlerCondition operationForCondition:aCondition entry:anEntry];
		#ifdef __DEBUG__
		NSLog([conditionOp description]); 
		#endif
		
		if ( conditionOp == nil )
		{
			canAutotag = NO;
			break;
		}
		*/
	}
	
	return canAutotag;

}

- (BOOL) autotagEntry:(JournlerEntry*)anEntry add:(BOOL)add
{
	// support or conditioning so that the list number of conditions are set
	
	if ( anEntry == nil || ![self isSmartFolder] || ![self canAutotag:anEntry] )
		return NO;
	
	// attempt to autotag the entry based on my conditions and the conditions of my parents
	// this should be a category on ns predicate
	
	BOOL added = YES;
	
	NSArray *allConditions = [self allConditions:YES];
	#ifdef __DEBUG __
	NSLog([allConditions description]);
	#endif
	
	NSDictionary *aDictionary;
	NSEnumerator *enumerator = [allConditions objectEnumerator];
	
	// supported conditions:
	// 1. title	2. category	3. keywords 4. label 5. mark
	
	while ( aDictionary = [enumerator nextObject] )
	{
		
		NSString *aCondition;
		NSArray *localConditions = [aDictionary objectForKey:@"conditions"];
		NSEnumerator *localEnumerator = [localConditions objectEnumerator];
		NSNumber *localCombination = [aDictionary objectForKey:@"combinationStyle"];
		
		BOOL alreadyAddedLocal = NO;
		
		while ( aCondition = [localEnumerator nextObject] )
		{
			NSDictionary *conditionOp = [JournlerCondition operationForCondition:aCondition entry:anEntry];
			#ifdef __DEBUG_
			NSLog([conditionOp description]); 
			#endif
			
			if ( conditionOp == nil )
			{
				// don't worry about it, a later condition will suffice (we already checked for canAutotag, so it should be there)
				if ( [localCombination intValue] == 0 )
					continue;
				
				// otherwise, we're finished
				else if ( [localCombination intValue] == 1 )
				{
					added = NO;
					goto bail;
				}
			}
			
			// we're finished if one of the conditions from this set has already been added and the op is any
			else if ( alreadyAddedLocal == YES && [localCombination intValue] == 0 )
				continue;
			
			id theOriginalValue;
			
			id theValue = [conditionOp objectForKey:kOperationDictionaryKeyValue];
			NSString *theKey = [conditionOp objectForKey:kOperationDictionaryKeyKey];
			NSInteger theOperation = [[conditionOp objectForKey:kOperationDictionaryKeyOperation] intValue];
			
			if ( [theValue isKindOfClass:[NSString class]] && [theValue length] == 1 && [theValue characterAtIndex:0] == '^' )
				theValue = [NSString string];
			
			switch ( theOperation )
			{
			case kKeyOperationNilOut:
				// the simplest operation, for use with tags right now
				[anEntry setValue:nil forKey:theKey];
				break;
				
			case kKeyOperationAddObjects:
				
				// use a set for the tags key ( theKey == "tags" ) so that the array is composed of unique objects
				theOriginalValue = (NSMutableArray*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				
				if ( [theKey isEqualToString:@"tags"] )
				{
					NSString *aTag;
					NSEnumerator *enumerator = [theValue objectEnumerator];
					while ( aTag = [enumerator nextObject] )
					{
						if ( ![theOriginalValue containsObject:aTag] )
							[(NSMutableArray*)theOriginalValue addObject:aTag];
					}
				}
				else
				{
					[(NSMutableArray*)theOriginalValue addObjectsFromArray:theValue];
				}
				
				[anEntry setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationRemoveObjects:
				theOriginalValue = (NSMutableArray*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				[(NSMutableArray*)theOriginalValue removeObjectsInArray:theValue];
				[anEntry setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationSetString:
				
				theOriginalValue = (NSMutableString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				[(NSMutableString*)theOriginalValue setString:theValue];
				[anEntry setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationSetNumber:
				
				// easy
				[anEntry setValue:theValue forKey:theKey];
				break;
			
			/*
			case kKeyOperationSetAttributedString:
				
				theOriginalValue = [[[NSAttributedString alloc] initWithString:theValue attributes:[JournlerEntry defaultTextAttributes]] autorelease];
				[self setValue:theOriginalValue forKey:theKey];
				break;
			*/
			
			case kKeyOperationAppendString:
				
				theOriginalValue = (NSMutableString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				
				if ( [theOriginalValue length] == 0 )
					[(NSMutableString*)theOriginalValue setString:theValue];
				else if ( [theOriginalValue rangeOfString:theValue options:NSCaseInsensitiveSearch range:NSMakeRange(0,[theOriginalValue length])].location == NSNotFound )
					[(NSMutableString*)theOriginalValue appendFormat:@" %@", theValue];
					
				[anEntry setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationRemoveString:
				
				theOriginalValue = (NSMutableString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				[(NSMutableString*)theOriginalValue replaceOccurrencesOfString:theValue 
						withString:[NSString string] options:NSCaseInsensitiveSearch range:NSMakeRange(0,[theOriginalValue length])];
						
						
				[anEntry setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationPrependString:
				
				theOriginalValue = (NSMutableString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				
				if ( [theOriginalValue length] == 0 )
					[(NSMutableString*)theOriginalValue setString:theValue];
				else if ( [theOriginalValue rangeOfString:theValue options:NSCaseInsensitiveSearch range:NSMakeRange(0,[theOriginalValue length])].location != 0 )
					[(NSMutableString*)theOriginalValue insertString:[NSString stringWithFormat:@"%@ ", theValue] atIndex:0];
					
				[anEntry setValue:theOriginalValue forKey:theKey];
				break;
			
			/*
			case kKeyOperationAppendAttributedString:
				
				theOriginalValue = (NSMutableAttributedString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				if ( [theOriginalValue length] == 0 )
					[(NSMutableAttributedString*)theOriginalValue setAttributedString:
					[[[NSAttributedString alloc] initWithString:theValue attributes:[JournlerEntry defaultTextAttributes]] autorelease]];
				else
					[(NSMutableAttributedString*)theOriginalValue replaceCharactersInRange:NSMakeRange([theOriginalValue length],0) withString:[NSString stringWithFormat:@" %@", theValue]];
				
				[anEntry setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationRemoveAttributedString:
				
				theOriginalValue = (NSMutableAttributedString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				//else if ( [[(NSMutableAttributedString*) theOriginalValue string] rangeOfString:theValue options:NSCaseInsensitiveSearch range:NSMakeRange(0,[theOriginalValue length])].location != 0 )
				//	[(NSMutableAttributedString*)theOriginalValue 
				#warning get the else here working
				
				[anEntry setValue:theOriginalValue forKey:theKey];
				break;
			
			case kKeyOperationPrependAttributedString:
				
				theOriginalValue = (NSMutableAttributedString*)[[[anEntry valueForKey:theKey] mutableCopyWithZone:[self zone]] autorelease];
				if ( [theOriginalValue length] == 0 )
					[(NSMutableAttributedString*)theOriginalValue setAttributedString:
					[[[NSAttributedString alloc] initWithString:theValue attributes:[JournlerEntry defaultTextAttributes]] autorelease]];
				else
					[(NSMutableAttributedString*)theOriginalValue replaceCharactersInRange:NSMakeRange(0,0) withString:[NSString stringWithFormat:@"%@ ", theValue]];
					
				[anEntry setValue:theOriginalValue forKey:theKey];
				break;
			*/
			}
			
			
			alreadyAddedLocal = YES;
		}
	}

bail:
	
	// actually add the entry to ourselves if everything worked
	if ( add == YES && added == YES)
		[self addEntry:anEntry];
	
	return added;
}


#pragma mark -
#pragma mark Menu Representation

- (BOOL) flatMenuRepresentation:(NSMenu**)aMenu 
		target:(id)object 
		action:(SEL)aSelector 
		smallImages:(BOOL)useSmallImages 
		inset:(NSInteger)level 
{
	NSMenu *menu = *aMenu;
	NSArray *theChildren = [self children];
	
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

- (NSMenu*) undelegatedMenuRepresentation:(id)target 
		action:(SEL)aSelector 
		smallImages:(BOOL)useSmallImages 
		includeEntries:(BOOL)wEntries
{
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	NSArray *theChildren = [self children];
	
	NSInteger i;
	for ( i = 0; i < [theChildren count]; i++ ) 
	{
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];

		// add each child to the menu, submenus if necessary
		JournlerCollection *aChild = [theChildren objectAtIndex:i];
		NSString *childTitle = [aChild title];
		if ( childTitle == nil ) childTitle = [NSString string];
		
		NSMenuItem *item = [[[NSMenuItem alloc] 
				initWithTitle:childTitle 
				action:aSelector 
				keyEquivalent:@""] autorelease];
		
		NSImage *itemImage;
		
		if ( useSmallImages ) 
			itemImage = [[aChild valueForKey:@"icon"] imageWithWidth:18 height:18 inset:0];
		else
			itemImage = [[aChild valueForKey:@"icon"] imageWithWidth:32 height:32 inset:0];
					
		[item setTarget:target];
		[item setTag:[[aChild valueForKey:@"tagID"] intValue]];
		[item setImage:itemImage];
		[item setRepresentedObject:aChild];
		
		if ( [aChild countOfChildren] != 0 || ( wEntries && [[aChild entries] count] != 0 ) )
			[item setSubmenu:[aChild undelegatedMenuRepresentation:target 
					action:aSelector 
					smallImages:useSmallImages 
					includeEntries:wEntries]];
		
		[menu addItem:item];
		[innerPool release];
	}
	
	// add the entries if that's been requested
	if ( wEntries && [[self entries] count] != 0 )
	{
		// separator item
		if ( [[menu itemArray] count] != 0 )
			[menu addItem:[NSMenuItem separatorItem]];
		
		NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] initWithKey:@"title" 
				ascending:YES 
				selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
				
		NSArray *myEntries = [[self entries] sortedArrayUsingDescriptors:[NSArray arrayWithObject:titleSort]];
		
		for ( i = 0; i < CFArrayGetCount((CFArrayRef)myEntries); i++ )
		{
			NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
			JournlerEntry *anEntry = (JournlerEntry*)CFArrayGetValueAtIndex((CFArrayRef)myEntries,i);
			NSString *entryTitle = [anEntry title];
			if ( entryTitle == nil ) entryTitle = [NSString string];
			
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:entryTitle 
					action:aSelector 
					keyEquivalent:@""] autorelease];
				
			[item setTarget:target];
			[item setRepresentedObject:anEntry];
			
			[menu addItem:item];
			[innerPool release];
		}
	}
	
	return menu;	
}

- (NSMenu*) menuRepresentation:(id)target 
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
	menuRepresentationOptions = kJournlerFolderMenuDefaultSettings;
	if ( wEntries ) menuRepresentationOptions |= kJournlerFolderMenuIncludesEntries;
	if ( useSmallImages == NO ) menuRepresentationOptions |= kJournlerFolderMenuUseLargeImages;
	
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
	NSInteger childCount = [[self children] count];
	NSInteger entriesCount = [[self entries] count];
	NSInteger totalCount = childCount + entriesCount;
	
	// get my menu item - it holds the target and action
	NSMenuItem *superItem = [[menu supermenu] itemAtIndex:[[menu supermenu] indexOfItemWithSubmenu:menu]];
	
	BOOL onChildren = ( index < childCount );
	NSInteger actualIndex = ( onChildren ? index : index - childCount );
	
	if ( onChildren )
	{
		NSArray *theChildren = [self children];
		JournlerCollection *aChild = [theChildren objectAtIndex:actualIndex];
			
		NSImage *itemImage = nil;
		if ( menuRepresentationOptions & kJournlerFolderMenuUseLargeImages )
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
				|| ( ( menuRepresentationOptions & kJournlerFolderMenuIncludesEntries ) 
					&& [[aChild entries] count] != 0 ) )
			//[item setSubmenu:[aChild 
			//	menuRepresentation:nil 
			//	action:nil 
			//	smallImages:!( menuRepresentationOptions & kJournlerFolderMenuUseLargeImages ) 
			//	includeEntries:( menuRepresentationOptions & kJournlerFolderMenuIncludesEntries )]];
			[item setSubmenu:[aChild undelegatedMenuRepresentation:[superItem target] 
					action:[superItem action] 
					smallImages:!( menuRepresentationOptions & kJournlerFolderMenuUseLargeImages ) 
					includeEntries:( menuRepresentationOptions & kJournlerFolderMenuIncludesEntries )]];
	}
	else if ( menuRepresentationOptions & kJournlerFolderMenuIncludesEntries )
	{
		// only if it includes the entries and we have entries
				
		// separator item
		if ( index == childCount && ( childCount > 0 && entriesCount > 0 ) )
		{
			if ( index != 0 ) {
				[menu removeItemAtIndex:index];
				[menu insertItem:[NSMenuItem separatorItem] atIndex:index];
				// modifying the menu midstream here, but doesn't seem to cause any problems
			}
			
			//if ( [item respondsToSelector:@selector(_configureAsSeparatorItem)] )
			//	[item _configureAsSeparatorItem];
			//	-- doesn't work
		}
		else
		{
			if ( childCount > 0 && entriesCount > 0 )
				actualIndex--;
			
			NSSortDescriptor *titleSort = [[[NSSortDescriptor alloc] initWithKey:@"title" 
					ascending:YES 
					selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
					
			NSArray *myEntries = [[self entries] sortedArrayUsingDescriptors:[NSArray arrayWithObject:titleSort]];
			JournlerEntry *anEntry = (JournlerEntry*)CFArrayGetValueAtIndex((CFArrayRef)myEntries,actualIndex);
			
			[item setTitle:[anEntry title]];
			[item setTarget:nil];
			[item setRepresentedObject:anEntry];
			
			[item setTarget:[superItem target]];
			[item setAction:[superItem action]];

		}
	}
		
	[pool release];

	return ( index < totalCount );
}

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
	NSInteger childCount = [[self children] count];
	NSInteger entriesCount = [[self entries] count];
	NSInteger totalCount = 0;
	
	//NSLog(@"%@ %s - total count: %i", [self className], _cmd, childCount + entriesCount);
	
	// check if we're adding entries
	if ( menuRepresentationOptions & kJournlerFolderMenuIncludesEntries )
	{
		totalCount = childCount + entriesCount;
		if ( childCount > 0 && entriesCount > 0 ) totalCount++;
		// one for the separator item but only if showing entries and children
	}
	else
	{
		totalCount = childCount;
	}

	return totalCount;
}

#pragma mark -

- (void) updateForTwoZero 
{
	// handle the unnecessary timestamp condition
	NSInteger i;
	NSArray *conditions = [self conditions];
	NSMutableArray *modifiedConditions = [[NSMutableArray alloc] initWithCapacity:[conditions count]];
	
	for ( i = 0; i < [conditions count]; i++ ) 
	{
		if ( [[conditions objectAtIndex:i] rangeOfString:@"timestamp" options:NSLiteralSearch].location != 0 )
			[modifiedConditions addObject:[conditions objectAtIndex:i]];
	}
	
	[self setConditions:modifiedConditions];
}

#pragma mark -

- (BOOL) isDescendantOfFolder:(JournlerCollection*)node {
    // returns YES if 'node' is an ancestor.
    // Walk up the tree, to see if any of our ancestors is 'node'.
    JournlerCollection *myParent = self;
    while( myParent) 
	{
       if ( myParent==node ) 
			return YES;
		
        myParent = [myParent valueForKey:@"parent"];
		
		// stop at the root collection
		if ( [[myParent valueForKey:@"tagID"] intValue] == -1 )
			myParent = nil;
	}
    return NO;
}

- (BOOL)isDescendantOfFolderInArray:(NSArray*)nodes {
    // returns YES if any 'node' in the array 'nodes' is an ancestor of ours.
    // For each node in nodes, if node is an ancestor return YES.  If none is an
    // ancestor, return NO.
    
	NSEnumerator *nodeEnum = [nodes objectEnumerator];
    JournlerCollection *node = nil;
	
    while( node = [nodeEnum nextObject] ) 
	{
        if( [self isDescendantOfFolder:node]) 
			return YES;
    }
    return NO;
}


- (BOOL) isMemberOfSmartFamilyConsideringSelf:(BOOL)includeSelf 
{
	
	if ( includeSelf && [self isSmartFolder] ) 
		return YES;
	
	BOOL inSmart = NO;
	JournlerCollection *aParent = self;
	while ( aParent = [aParent parent] ) 
	{
		if ( aParent == nil || [[aParent valueForKey:@"tagID"] intValue] == -1 ) 
			break;
		
		if ( [[aParent valueForKey:@"typeID"] intValue] == PDCollectionTypeIDSmart ) 
		{
			inSmart = YES;
			break;
		}
	}
	
	return inSmart;
}

#pragma mark -

- (NSString*) packagePath
{
	NSString *entryPath;
	NSString *completePath;
	
	entryPath = [NSString stringWithFormat:@"%@.jcol", [self tagID]];
	completePath = [[[self journal] pathForSupportDocumentOrDirectory:JournlerFoldersDirectory] stringByAppendingPathComponent:entryPath];
	
	return completePath;
}

- (BOOL) writeEntriesToFolder:(NSString*)directoryPath 
		format:(NSInteger)fileType 
		considerChildren:(BOOL)recursive 
		includeHeaders:(BOOL)headers; 
{
	
	NSInteger i;
	BOOL dir;
	BOOL completeSuccess = YES;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	//if ( ![self entries] || [[self entries] count] == 0 ) return NO;
	if ( ![fm fileExistsAtPath:directoryPath isDirectory:&dir] || !dir ) return NO;
	
	// check up on the kids and the provided path
	NSArray *theEntries = [self entries];
	
	// make sure a path for this folder exists
	NSString *pathToMe = [[directoryPath stringByAppendingPathComponent:[self pathSafeTitle]] pathWithoutOverwritingSelf];
					
	if ( ![fm fileExistsAtPath:pathToMe isDirectory:&dir] || !dir )
		[fm createDirectoryAtPath:pathToMe attributes:nil];
	
	// entry save flags
	NSInteger flags = kEntrySetLabelColor;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportIncludeHeader"] )
		flags |= kEntryIncludeHeader;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetCreationDate"] )
		flags |= kEntrySetFileCreationDate;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EntryExportSetModificationDate"] )
		flags |= kEntrySetFileModificationDate;
	
	// write out the entries
	for ( i = 0; i < [theEntries count]; i++ ) 
	{
		JournlerEntry *anEntry = [theEntries objectAtIndex:i];
		NSString *entry_destination = [[pathToMe stringByAppendingPathComponent:[anEntry pathSafeTitle]] pathWithoutOverwritingSelf];
		
		completeSuccess = ( [anEntry writeToFile:entry_destination as:fileType flags:flags] && completeSuccess );
	}
	
	// handle the kids
	if ( recursive ) 
	{
		NSInteger k;
		NSArray *kids = [[self children] copyWithZone:[self zone]];
		if ( kids != nil ) 
		{
			for ( k = 0; k < [kids count]; k++ )
				completeSuccess = ( [[kids objectAtIndex:k] writeEntriesToFolder:pathToMe 
						format:fileType 
						considerChildren:recursive 
						includeHeaders:headers] && completeSuccess );
		}
		
		[kids release];
	}
	
	return completeSuccess;
}

#pragma mark -

- (BOOL) isRegularFolder
{
	return ( [[self valueForKey:@"typeID"] intValue] == PDCollectionTypeIDFolder );
}

- (BOOL) isSmartFolder
{
	return ( [[self valueForKey:@"typeID"] intValue] == PDCollectionTypeIDSmart );
}

- (BOOL) isTrash
{
	return ( [[self valueForKey:@"typeID"] intValue] == PDCollectionTypeIDTrash );
}

- (BOOL) isLibrary
{
	return ( [[self valueForKey:@"typeID"] intValue] == PDCollectionTypeIDLibrary );
}

- (BOOL) isSeparatorFolder
{
	return ( [[self valueForKey:@"typeID"] intValue] == PDCollectionTypeIDSeparator );
}

#pragma mark -

- (void) perform253Maintenance
{
	[_properties removeObjectForKey:@"PDCollectionEntryTableState"];
	[_properties removeObjectForKey:PDCollectionImage];
	
	if ( [[_properties objectForKey:PDCollectionLabel] intValue] == 0 )
		[_properties removeObjectForKey:PDCollectionLabel];
		
	if ( [[_properties objectForKey:PDCollectionPreds] count] == 0 )
		[_properties removeObjectForKey:PDCollectionPreds];
}

#pragma mark -

- (NSScriptObjectSpecifier *)objectSpecifier 
{	
	NSUniqueIDSpecifier *specifier;

	NSScriptClassDescription* appDesc = (NSScriptClassDescription*)[NSApp classDescription];
	
	specifier = [[NSUniqueIDSpecifier allocWithZone:[self zone]]
			initWithContainerClassDescription:appDesc 
			containerSpecifier:nil
			key:@"JSFolders" uniqueID:[self tagID]];
		
	return [specifier autorelease];
}

@end

#pragma mark -

@implementation JournlerCollection (JournlerScriptability)

#pragma mark -

- (OSType) scriptType
{
	OSType scriptType = 'ftFL';
	
	switch ( [[self valueForKey:@"typeID"] intValue] )
	{
	case PDCollectionTypeIDLibrary:
		scriptType = 'ftLI';
		break;
	case PDCollectionTypeIDTrash:
		scriptType = 'ftTR';
		break;
	case PDCollectionTypeIDFolder:
		scriptType = 'ftFL';
		break;
	case PDCollectionTypeIDSmart:
		scriptType = 'flSF';
		break;
	}
	
	return scriptType;
}

- (void) setScriptType:(OSType)osType
{
	NSInteger type = PDCollectionTypeIDFolder;
	
	switch ( osType )
	{
	case 'ftLI':
		type = PDCollectionTypeIDLibrary;
		break;
	case 'ftTR':
		type = PDCollectionTypeIDTrash;
		break;
	case 'ftFL':
		type = PDCollectionTypeIDFolder;
		break;
	case 'flSF':
		type = PDCollectionTypeIDSmart;
		break;
	}
	
	[self setValue:[NSNumber numberWithInt:type] forKey:@"typeID"];

}

- (OSType) scriptLabel
{
	OSType scriptLabel = 'lcCE';
	
	switch ( [[self valueForKey:@"label"] intValue] )
	{
	case 0:
		scriptLabel = 'lcCE';
		break;
	case 1:
		scriptLabel = 'lcRE';
		break;
	case 2:
		scriptLabel = 'lcOR';
		break;
	case 3:
		scriptLabel = 'lcYE';
		break;
	case 4:
		scriptLabel = 'lcGN';
		break;
	case 5:
		scriptLabel = 'lcBL';
		break;
	case 6:
		scriptLabel = 'lcPU';
		break;
	case 7:
		scriptLabel = 'lcGY';
		break;
	default:
		scriptLabel = 'lcCE';
		break;
	}
	
	return scriptLabel;
}

- (void) setScriptLabel:(OSType)osType
{
	NSInteger label = 0;
	
	switch ( osType )
	{
	case 'lcCE':
		label = 0;
		break;
	case 'lcRE':
		label = 1;
		break;
	case 'lcOR':
		label = 2;
		break;
	case 'lcYE':
		label = 3;
		break;
	case 'lcGN':
		label = 4;
		break;
	case 'lcBL':
		label = 5;
		break;
	case 'lcPU':
		label = 6;
		break;
	case 'lcGY':
		label = 7;
		break;
	default:
		label = 0;
		break;
	}
	
	[self setValue:[NSNumber numberWithInt:label] forKey:@"label"];

}

- (NSNumber*)scriptCanAutotag
{
	return [NSNumber numberWithBool:[self canAutotag:nil]];
}

- (NSNumber*) scriptPosition
{
	return [self valueForKey:@"index"];
}

- (void) setScriptPosition:(NSNumber*)aNumber
{
	//NSInteger desiredIndex = [aNumber intValue];
	[self returnError:OSAMessageNotUnderstood string:@"It is not possible to set the folder's position"];
}

#pragma mark -
#pragma mark Entries

- (NSUInteger) indexOfObjectInJSEntries:(JournlerEntry*)anEntry {
	return [[self valueForKeyPath:@"entries"] indexOfObject:anEntry];
}

- (NSUInteger) countOfJSEntries {
	return [self countOfEntries];
}

- (JournlerEntry*) objectInJSEntriesAtIndex:(NSUInteger)anIndex {
	return [self objectInEntriesAtIndex:anIndex];
}

- (JournlerEntry*) valueInJSEntriesWithUniqueID:(NSNumber*)anId {
	return [[self valueForKeyPath:@"journal.entriesDictionary"] objectForKey:anId];
}

#pragma mark -
#pragma mark folders

- (NSUInteger) indexOfObjectInJSFolders:(JournlerCollection*)aFolder {
	return [[self valueForKeyPath:@"children"] indexOfObject:aFolder];
}

- (NSUInteger) countOfJSFolders { 
	return [self countOfChildren];
}

- (JournlerCollection*) objectInJSFoldersAtIndex:(NSUInteger)anIndex {
	return [self objectInChildrenAtIndex:anIndex];
}

- (JournlerCollection*) valueInJSFoldersWithUniqueID:(NSNumber*)anId {
	return [[self valueForKeyPath:@"journal.collectionsDictionary"] objectForKey:anId];
}

#pragma mark -
#pragma mark Script Commands

- (void) jsExport:(NSScriptCommand *)command
{
	
	NSDictionary *args = [command evaluatedArguments];
	
	BOOL dir = NO, includeSubfolders = NO, includeHeader = YES;
	NSUInteger fileType;
	OSType formatKeyCode = 'etRT';
	
	NSString *path;
	id pathURL = [args objectForKey:@"exportLocation"];
	id formatArg = [args objectForKey:@"exportFormat"];
	id exportSubfolders = [args objectForKey:@"exportSubfolders"];
	id headerArg = [args objectForKey:@"includeHeader"];
	
	if ( pathURL == nil || ![pathURL isKindOfClass:[NSURL class]] ) 
	{
		// raise an error
		NSLog(@"%@ %s - nil path or path other than url, but path is required", [self className], _cmd);
		[self returnError:errOSACantAssign string:nil];
		return;
	}
	
	path = [pathURL path];
	if ( [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] && dir )
		path = path;
	else
		path = [path stringByDeletingPathExtension];
	
	if ( exportSubfolders != nil && [exportSubfolders isKindOfClass:[NSNumber class]] )
		includeSubfolders = [exportSubfolders boolValue];
	
	// default to rtfd if no format is specified
	if ( formatArg != nil )
		formatKeyCode = (OSType)[formatArg unsignedIntValue];
	
	// include the headers? default is yes
	if ( headerArg != nil && [headerArg isKindOfClass:[NSNumber class]] )
		includeHeader = [headerArg boolValue];
	
	switch ( formatKeyCode )
	{
	case 'etRT': // rich text
		fileType = kEntrySaveAsRTF;
		break;
	case 'etRD': // rich text directory
		fileType = kEntrySaveAsRTFD;
		break;
	case 'etPD': // portable document format
		fileType = kEntrySaveAsPDF;
		break;
	case 'etDO': // word document
		fileType = kEntrySaveAsWord;
		break;
	case 'etTX': // plain text
		fileType = kEntrySaveAsText;
		break;
	case 'etXH': // xhtml
		fileType = kEntrySaveAsHTML;
		break;
	case 'etWA': // web archive
		fileType = kEntrySaveAsWebArchive;
		break;
	default:
		fileType = kEntrySaveAsRTF;
		break;
	}
	
	// write the file, error checking on the way
	if ( ![self writeEntriesToFolder:path format:fileType considerChildren:includeSubfolders includeHeaders:includeHeader] )
	{
		NSLog(@"%@ %s - unable to export entry to path %@ as type %i", [self className], _cmd, path, fileType);
		[self returnError:OSAParameterMismatch string:@"File path is not valid or an error occurred creating the file."];
	}
	
}

- (void) jsAddFolderToFolder:(NSScriptCommand *)command 
{
	NSDictionary *args = [command evaluatedArguments];
	
	// try for a target using the move command
	id target_collection = [args objectForKey:@"targetCollection"];
	
	// if not, try for a target using the add command
	if ( target_collection == nil )
		target_collection = [args objectForKey:@"ToLocation"];
	
	if ( target_collection == nil || ![target_collection isKindOfClass:[JournlerCollection class]] ) {
		[self returnError:errOSACantAssign string:nil];
		return;
	}
	
	if ( [self isLibrary] || [self isTrash] || [target_collection isLibrary] || [target_collection isTrash] )
	{
		// do not allow the library or trash to be moved around
		[self returnError:errOSACantAssign string:nil];
		return;
	}
	
	// make the move, re-collecting if necessary
	BOOL wasInSmartFamily = [self isMemberOfSmartFamilyConsideringSelf:NO];
	
	[self retain];
	
	// remove the folder from its parent or root
	JournlerCollection *theParent = [self parent];
	if ( theParent != nil ) [[self parent] removeChild:self recursively:NO];
	else [[self journal] removeRootFolder:self];
	
	// and add the folder to its new target
	[(JournlerCollection*)target_collection addChild:self atIndex:-1];
	
	if ( wasInSmartFamily || [self isMemberOfSmartFamilyConsideringSelf:YES] )
	{
		[self invalidatePredicate:YES];
		[self evaluateAndAct:[self valueForKeyPath:@"journal.entries"] considerChildren:YES];
	}
	
	[self release];
}

- (void) jsMoveFolderToFolder:(NSScriptCommand *)command 
{
	// just call add folder's implementation
	[self jsAddFolderToFolder:command];
}

@end
