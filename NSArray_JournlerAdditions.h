//
//  NSArray_JournlerAdditions.h
//  JournlerCore
//
//  Created by Philip Dow on 11/3/06.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <Cocoa/Cocoa.h>

@class JournlerJournal;
@class JournlerResource;

@interface NSArray (JournlerAdditions)

/*!
	@function arrayProducingURIRepresentations
	@abstract Assuming the receiver is an array of JournlerObjects,
		returns an array of URI representations for those objects
	@discussion Uses the JournlerObject method URIRepresentation. Checks each item in the array first
		to be sure it responds to that method
	@param journal JournlerJournal object to use for the conversion. Not actualy used by the method.
	@result NSArray array of URI representations for the JournlerObjects contained in the receiver
*/

- (NSArray*) arrayProducingURIRepresentations:(JournlerJournal*)journal;

/*!
	@function arrayProducingJournlerObjects
	@abstract Assuming the receiver is an array of JournlerObject URI representations,
		returns an array of the corresponding real Journler objects.
	@discussion Uses the JournlerJournal method objectForURIRepresentation to make the conversion
	@param journal JournlerJournal object to use for the conversion.
	@result NSArray array of real JournlerJournal objects
*/

- (NSArray*) arrayProducingJournlerObjects:(JournlerJournal*)journal;

/*!
	@function indexOfObjectIdenticalToResource
	@abstract If the receiver contains a resource identical to the one provided, returns the index of that object.
	@discussion JournlerResources do not have to be the same object to be identical. 
		The hash for a resource uses the objects unique id. The isEqual method checks the URI representation.
		This method uses isEqualToResource, which makes a comparison based on the underlying data.
	@param aResource JournlerResource to test against.
	@result NSArray array of real JournlerJournal objects
*/

- (NSUInteger) indexOfObjectIdenticalToResource:(JournlerResource*)aResource;

@end
