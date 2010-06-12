//
//  EntryViewController.h
//  JournlerCore
//
//  Created by greay on 3/25/10.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EntryViewController : NSViewController {
	
	IBOutlet NSFormCell *titleCell;
	IBOutlet NSFormCell *dateCell;
	IBOutlet NSFormCell *categoryCell;
	IBOutlet NSFormCell *tagsCell;
	
	IBOutlet NSTextView *textView;
}

@property (nonatomic, retain) NSFormCell *titleCell;
@property (nonatomic, retain) NSFormCell *dateCell;
@property (nonatomic, retain) NSFormCell *categoryCell;
@property (nonatomic, retain) NSFormCell *tagsCell;

@property (nonatomic, retain) NSTextView *textView;

@end