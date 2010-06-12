//
//  EntryViewController.h
//  JournlerCore
//
//  Created by greay on 3/25/10.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JournlerCore/JournlerCore.h>

@interface EntryViewController : NSViewController {
	
	JournlerEntry *entry;
	
	NSFormCell *titleCell;
	NSFormCell *dateCell;
	NSFormCell *categoryCell;
	NSFormCell *tagsCell;
	
	NSTextView *textView;
}

@property (nonatomic, retain) JournlerEntry *entry;

@property (nonatomic, retain) IBOutlet NSFormCell *titleCell;
@property (nonatomic, retain) IBOutlet NSFormCell *dateCell;
@property (nonatomic, retain) IBOutlet NSFormCell *categoryCell;
@property (nonatomic, retain) IBOutlet NSFormCell *tagsCell;

@property (nonatomic, retain) IBOutlet NSTextView *textView;

@end