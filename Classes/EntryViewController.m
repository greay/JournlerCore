//
//  EntryViewController.m
//  JournlerCore
//
//  Created by greay on 3/25/10.
//  Copyright 2010 Übermind, Inc. All rights reserved.
//

#import "EntryViewController.h"


@implementation EntryViewController

@synthesize textView;

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