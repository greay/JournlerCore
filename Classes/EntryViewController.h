//
//  EntryViewController.h
//  JournlerCore
//
//  Created by greay on 3/25/10.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EntryViewController : NSViewController {
	IBOutlet NSTextView *textView;
}

@property (nonatomic, retain) NSTextView *textView;

@end