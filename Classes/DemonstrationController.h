//
//  DemonstrationController.h
//  JournlerCore Demonstration
//
//  Created by Philip Dow on 7/17/09.
//  Copyright 2009 Lead Developer, Journler Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JournlerCore/JournlerCore.h>

#import "LibraryController.h";
#import "EntriesController.h"

@interface DemonstrationController : NSWindowController <NSTableViewDelegate, NSDatePickerCellDelegate> {
	
	IBOutlet NSDatePicker *calendar;

	IBOutlet LibraryController *libraryController;
	IBOutlet NSTableView *library;

	IBOutlet EntriesController *entriesController;
	IBOutlet NSTableView *entries;

	JournlerEntry *currentEntry;
	IBOutlet NSView *entryView;
	IBOutlet NSTextView *textView;
}

@property (nonatomic, retain) JournlerEntry *currentEntry;

- (void)loadJournal;
- (void)updateTextView:(NSString*)text;
- (void)updateEntry:(JournlerEntry *)entry text:(NSAttributedString *)text;

- (IBAction)newEntry:(id)sender;

@end
