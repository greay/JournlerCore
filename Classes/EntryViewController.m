//
//  EntryViewController.m
//  JournlerCore
//
//  Created by greay on 3/25/10.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import "EntryViewController.h"


@implementation EntryViewController


#pragma mark -

@synthesize titleCell, dateCell, categoryCell, tagsCell, textView;

- (void)setEntry:(JournlerEntry *)anEntry {
	[entry release];
	entry = [anEntry retain];
	
	NSAttributedString *str = nil;
	if (entry && [entry contents]) {
		str = [entry contents];
	} else {
		str = [[[NSAttributedString alloc] initWithString:@""] autorelease];
	}
	
	[self.titleCell setObjectValue:[entry title]];
	[self.dateCell setObjectValue:[entry calDate]];
	[self.categoryCell setObjectValue:[entry category]];
	[self.tagsCell setObjectValue:[[entry tags] componentsJoinedByString:@","]];
	
	[[self.textView textStorage] setAttributedString:str];
}

- (JournlerEntry *)entry {
	return entry;
}

#pragma mark -

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSLog(@"***EntryViewController initWithNibName:%@ bundle:%@", nibNameOrNil, nibBundleOrNil);
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

- (id)init
{
	NSLog(@"***EntryViewController init");
	self = [super init];
	return self;
}

- (void)loadView
{
	NSLog(@"***EntryViewController loadView");
	[super loadView];
}

- (void)dealloc {
	[textView release];
	[super dealloc];
}

@end