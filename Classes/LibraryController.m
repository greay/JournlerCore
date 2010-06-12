//
//  LibraryController.m
//  JournlerCore
//
//  Created by greay on 3/18/10.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import "LibraryController.h"
#import <JournlerCore/JournlerCore.h>


@implementation LibraryController

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[[JournlerJournal sharedJournal] collections] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [[[[JournlerJournal sharedJournal] collections] objectAtIndex:rowIndex] title];
}

@end
