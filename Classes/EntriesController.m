//
//  EntriesController.m
//  JournlerCore
//
//  Created by greay on 3/18/10.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import "EntriesController.h"
#import <JournlerCore/JournlerCore.h>


@implementation EntriesController

@synthesize collection;

- (id)init {
	self = [super init];
	return self;
}

- (void)dealloc {
	[collection release];
	[super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[collection entries] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	NSString *identifier = [aTableColumn identifier];
	JournlerEntry *entry = [[collection entries] objectAtIndex:rowIndex];
	if ([identifier isEqualToString:@"entry"]) {
		return [entry tagID];
	} else if ([identifier isEqualToString:@"title"]) {
		return [entry title];
	} else if ([identifier isEqualToString:@"created"]) {
		return [entry calDate];
	} else if ([identifier isEqualToString:@"modded"]) {
		return [entry calDateModified];
	} else {
		return @"";
	}
}

@end
