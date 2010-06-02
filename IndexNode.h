//
//  IndexNode.h
//  JournlerCore
//
//  Created by Philip Dow on 2/6/07.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <Cocoa/Cocoa.h>

@class JournlerObject;

@interface IndexNode : NSObject <NSCopying> {
	
	NSInteger count;
	NSInteger frequency;
	NSString *title;
	
	IndexNode *parent;
	NSMutableArray *children;
	
	id representedObject;
}

- (NSInteger) count;
- (void) setCount:(NSInteger)aCount;

- (NSInteger) frequency;
- (void) setFrequency:(NSInteger)aFrequency;

- (NSString*) title;
- (void) setTitle:(NSString*)aString;

- (id) representedObject;
- (void) setRepresentedObject:(id)anObject;

- (IndexNode*) parent;
- (void) setParent:(IndexNode*)aNode;

#pragma mark -
#pragma mark children

- (NSArray*) children;
- (void) setChildren:(NSArray*)anArray;

- (NSUInteger) countOfChildren;
- (id) objectInChildrenAtIndex:(NSUInteger)theIndex;
- (void) getChildren:(id *)objsPtr range:(NSRange)range;
- (void) insertObject:(id)obj inChildrenAtIndex:(NSUInteger)theIndex;

- (void) removeObjectFromChildrenAtIndex:(NSUInteger)theIndex;
- (void) replaceObjectInChildrenAtIndex:(NSUInteger)theIndex withObject:(id)obj;

- (unsigned) childCount;
- (BOOL) isLeaf;

@end
