//
//  IndexNode.m
//  JournlerCore
//
//  Created by Philip Dow on 2/6/07.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <JournlerCore/IndexNode.h>


@implementation IndexNode

- (id) init
{
	if ( self = [super init] )
	{
		count = 0;
		title = [[NSString alloc] init];
		representedObject = nil;
		
		parent = nil;
		children = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	//#ifdef __DEBUG__
	//NSLog(@"%@ %s",[self className],_cmd);
	//#endif
	
	[title release], title = nil;
	[representedObject release], representedObject = nil;
	
	//[parent release]; // weak reference
	
	//[children setValue:nil forKey:@"parent"];
	[children release], children = nil;
	
	[super dealloc];
}

#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	IndexNode *newNode = [[[self class] allocWithZone:zone] init];
	
	[newNode setParent:[self parent]];
	[newNode setChildren:[self children]];
	
	[newNode setTitle:[self title]];
	[newNode setRepresentedObject:[self representedObject]];
	
	newNode->count = count;
	newNode->frequency = frequency;
	
	return newNode;
}

#pragma mark -

- (NSInteger) count
{
	return count;
}

- (void) setCount:(NSInteger)aCount
{
	count = aCount;
}

- (NSInteger) frequency
{
	return frequency;
}

- (void) setFrequency:(NSInteger)aFrequency
{
	frequency = aFrequency;
}

- (NSString*) title
{
	return title;
}

- (void) setTitle:(NSString*)aString
{
	if ( title != aString )
	{
		[title release];
		title = [aString copyWithZone:[self zone]];
	}
}

- (id) representedObject
{
	return representedObject;
}

- (void) setRepresentedObject:(id)anObject
{
	if ( representedObject != anObject )
	{
		[representedObject release];
		representedObject = [anObject retain];
	}
}

#pragma mark -

- (IndexNode*) parent
{
	return parent;
}

- (void) setParent:(IndexNode*)aNode
{
	if ( parent != aNode )
	{
		//[parent release];
		//parent = [aNode retain];
		parent = aNode;
	}
}

#pragma mark -
#pragma mark children

- (NSArray*) children
{
	return children;
}

- (void) setChildren:(NSArray*)anArray
{
	if ( children != anArray )
	{
		//[children setValue:nil forKey:@"parent"];
		
		[children release];
		children = [anArray mutableCopyWithZone:[self zone]];
		
		[children setValue:self forKey:@"parent"];
	}
}

#pragma mark -

- (NSUInteger)countOfChildren {
	return [children count];
}

- (id)objectInChildrenAtIndex:(NSUInteger)theIndex {
	return [children objectAtIndex:theIndex];
}

- (void)getChildren:(id *)objsPtr range:(NSRange)range {
	[children getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inChildrenAtIndex:(NSUInteger)theIndex {
	[children insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)theIndex {
	[children removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInChildrenAtIndex:(NSUInteger)theIndex withObject:(id)obj {
	[children replaceObjectAtIndex:theIndex withObject:obj];
}

#pragma mark -

- (unsigned) childCount
{
	return (unsigned)[children count];
}

- (BOOL) isLeaf
{
	return ( [children count] == 0 );
}

@end
