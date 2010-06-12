//
//  EntriesController.h
//  JournlerCore
//
//  Created by greay on 3/18/10.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JournlerCollection;
@interface EntriesController : NSObject <NSTableViewDataSource> {
	JournlerCollection *collection;
}

@property (nonatomic, retain) JournlerCollection *collection;

@end
