//
//	DemonstrationController.m
//	JournlerCore
//
//	Created by Philip Dow on 7/17/09.
//	Copyright 2009 Lead Developer, Journler Software. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "DemonstrationController.h"

@implementation DemonstrationController

@synthesize currentEntry;

#pragma mark -

- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	return self;
}

#pragma mark -

- (void)dealloc {
	[libraryController release];
	[library release];
	[entriesController release];
	[entries release];
	[entryViewController release];
	
	[super dealloc];
}

#pragma mark -

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{	
	// set up the shared journal
	[[JournlerJournal sharedJournal] setOwner:self];

}	

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// add journler's preferences to the user default's search list
	static NSString *kJournlerBundleIdentifier = @"com.phildow.journler";
	[[NSUserDefaults standardUserDefaults] addSuiteNamed:kJournlerBundleIdentifier];

	libraryController = [[LibraryController alloc] init];
	library.dataSource = libraryController;
	
	entriesController = [[EntriesController alloc] init];
	entries.dataSource = entriesController;
	
	[self loadJournal];
}

- (void)awakeFromNib {	
	[calendar setDateValue:[NSDate date]];
	[calendar setDelegate:self];

	[super awakeFromNib];

	NSLog(@"awakeFromNib...");
	
	entryViewController = [[EntryViewController alloc] initWithNibName:@"Entry" bundle:nil];

	[[entryViewController view] setFrame:[entryView frame]];
	[[entryView superview] replaceSubview:entryView with:[entryViewController view]];

}

- (void)loadWindow {
	// [super loadWindow];
	// NSLog(@"loadWindow...");
	// 
	// entryViewController = [[EntryViewController alloc] initWithNibName:@"Entry" bundle:nil];
	// 
	// [[entryViewController view] setFrame:[entryView frame]];
	// [[entryView superview] replaceSubview:entryView with:[entryViewController view]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	NSLog(@"saving");
	[self updateEntry:self.currentEntry text:[entryViewController.textView textStorage]];
	[[JournlerJournal sharedJournal] saveCollections:YES];
}

#pragma mark -

- (void)loadJournal
{
	NSInteger jError = 0;
	JournalLoadFlag loadResult;
	
	// get the location from Journler's preferences
	NSString *journalLocation = [[[NSUserDefaults standardUserDefaults] stringForKey:@"Default Journal Location"] stringByStandardizingPath];
	[self updateTextView:journalLocation];
	
	// this demonstration does not check for password protection
	// this demonstration does not perform error checking
	//	- the loadResult broadly describes any problems that may have occurred while loading
	//	- the jError more specifically indicates what may have gone wrong
	//	- see <JournlerCore/JournlerJournal.h> for more information about possible results
	//	- future demonstrations will include the complete load code
	
	loadResult = [[JournlerJournal sharedJournal] loadFromPath:journalLocation error:&jError];
	if ( jError ) {
		[self updateTextView:@"\nGot an error loading journal.\n"];
		
	//	[[JournlerJournal sharedJournal] release];
	}
	else {
		
		NSUInteger numberOfFolders = [[[JournlerJournal sharedJournal] collections] count];
		NSUInteger numberOfRootFolders = [[[JournlerJournal sharedJournal] rootFolders] count];
		
		NSUInteger numberOfEntries = [[[JournlerJournal sharedJournal] entries] count];
		NSUInteger numberOfResources = [[[JournlerJournal sharedJournal] resources] count];
		
		NSString *infoString = [NSString stringWithFormat:@"\nJournal Successfuly Loaded!!\nTotal Folders: %i\nTotal Root Folders: %i\nTotal Entries: %i\nTotal Resources: %i\n",
				numberOfFolders, numberOfRootFolders, numberOfEntries, numberOfResources];
		
		[self updateTextView:infoString];
		[library reloadData];
		
		// at this point you have complete read and write access to a user's journal
		// you can set up bindings or look at the entries, collections (folders), rootFolders and resources
		// by accessor methods.
		
		// writing to the journal does require a bit more effort, as changes must be saved
		// future editions of this demonstration code will include more detailed examples
		// of reading from and writing to the journal.
		
		// if you just can't wait to get started, email developer@journler.com and maybe I can help you out.
	}
}

- (void)updateTextView:(NSString*)text
{
	[[entryViewController.textView textStorage] beginEditing];
	[[entryViewController.textView textStorage] appendAttributedString:
 			[[[NSAttributedString alloc] initWithString:
 			[NSString stringWithFormat:@"\n%@\n",text]] autorelease]];
	[[entryViewController.textView textStorage] endEditing]; 
}

- (void)updateEntry:(JournlerEntry *)entry text:(NSAttributedString *)text {
	[entry setContents:text];
	[[JournlerJournal sharedJournal] saveEntry:entry];
}

- (void)beginEditingEntry:(JournlerEntry *)entry {
	self.currentEntry = entry;

	NSAttributedString *str = nil;
	if (entry && [entry contents]) {
		str = [entry contents];
	} else {
		str = [[[NSAttributedString alloc] initWithString:@""] autorelease];
	}
	
    [entryViewController.titleCell setObjectValue:[entry title]];
    [entryViewController.dateCell setObjectValue:[entry calDate]];
    [entryViewController.categoryCell setObjectValue:[entry category]];
    [entryViewController.tagsCell setObjectValue:[[entry tags] componentsJoinedByString:@","]];
	
	[[entryViewController.textView textStorage] setAttributedString:str];
}

#pragma mark -



- (IBAction)newEntry:(id)sender {
	JournlerEntry *entry = [[JournlerEntry alloc] init];
	[entry setTitle:@"Untitled"];
	[entry setContents:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	[[JournlerJournal sharedJournal] addEntry:entry];
	[self beginEditingEntry:entry];
	[entry release];
}


#pragma mark -


- (void)tableViewSelectionDidChange:(NSNotification *)note {
	if ([note object] == library) {
		int i = [library selectedRow];
		entriesController.collection = [[[JournlerJournal sharedJournal] collections] objectAtIndex:i];
		[entries reloadData];
		[entries deselectAll:nil];
	} else if ([note object] == entries) {
		int i = [entries selectedRow];
		NSLog(@"selected entry %d", i);

		JournlerEntry *entry;
		if (i >= 0) {
			entry = [[entriesController.collection entries] objectAtIndex:i];
		} else {
			entry = nil;
		}
		[self updateEntry:self.currentEntry text:[entryViewController.textView textStorage]];
		[self beginEditingEntry:entry];
	} else {
		NSLog(@"wtf");
	}
}

#pragma mark -

- (void)textDidEndEditing:(NSNotification *)aNotification {
	NSLog(@"ended editing");
	// [currentEntry setContents:[textView textStorage]];
}

#pragma mark -
- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell validateProposedDateValue:(NSDate **)proposedDateValue timeInterval:(NSTimeInterval *)proposedTimeInterval
{
	
}

		   

@end
