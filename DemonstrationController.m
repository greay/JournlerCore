//
//  DemonstrationController.m
//  JournlerCore
//
//  Created by Philip Dow on 7/17/09.
//  Copyright 2009 Lead Developer, Journler Software. All rights reserved.
//

#import "DemonstrationController.h"


@implementation DemonstrationController

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{	
	// set up the shared journal
	mJournal = [[JournlerJournal alloc] init];
	[mJournal setOwner:self];
}	

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// add journler's preferences to the user default's search list
	static NSString *kJournlerBundleIdentifier = @"com.phildow.journler";
	[[NSUserDefaults standardUserDefaults] addSuiteNamed:kJournlerBundleIdentifier];
}

- (IBAction) startIt:(id)sender
{
	[self loadJournal];
}

#pragma mark ~

- (void) loadJournal
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
	
	loadResult = [mJournal loadFromPath:journalLocation error:&jError];
	if ( jError ) {
		[self updateTextView:@"\nGot an error loading journal. The Journal has been released from memory.\n"];
		
		[mJournal release];
		mJournal = nil;
	}
	else {
		
		NSUInteger numberOfFolders = [[mJournal collections] count];
		NSUInteger numberOfRootFolders = [[mJournal rootFolders] count];
		
		NSUInteger numberOfEntries = [[mJournal entries] count];
		NSUInteger numberOfResources = [[mJournal resources] count];
		
		NSString *infoString = [NSString stringWithFormat:@"\nJournal Successfuly Loaded!!\nTotal Folders: %i\nTotal Root Folders: %i\nTotal Entries: %i\nTotal Resources: %i\n",
				numberOfFolders, numberOfRootFolders, numberOfEntries, numberOfResources];
		
		[self updateTextView:infoString];
		
		// at this point you have complete read and write access to a user's journal
		// you can set up bindings or look at the entries, collections (folders), rootFolders and resources
		// by accessor methods.
		
		// writing to the journal does require a bit more effort, as changes must be saved
		// future editions of this demonstration code will include more detailed examples
		// of reading from and writing to the journal.
		
		// if you just can't wait to get started, email developer@journler.com and maybe I can help you out.
	}
}

- (void) updateTextView:(NSString*)text
{
	[[textView textStorage] beginEditing];
	[[textView textStorage] appendAttributedString:
			[[[NSAttributedString alloc] initWithString:
			[NSString stringWithFormat:@"\n%@\n",text]] autorelease]];
	[[textView textStorage] endEditing]; 
}

@end
