//
//  DemonstrationController.h
//  JournlerCore Demonstration
//
//  Created by Philip Dow on 7/17/09.
//  Copyright 2009 Lead Developer, Journler Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JournlerCore/JournlerCore.h>

@interface DemonstrationController : NSWindowController {
	
	IBOutlet NSTextView *textView;
	JournlerJournal *mJournal;
}

- (IBAction) startIt:(id)sender;

- (void) loadJournal;
- (void) updateTextView:(NSString*)text;

@end
