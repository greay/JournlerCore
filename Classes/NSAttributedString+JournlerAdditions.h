//
//  NSAttributedString+JournlerAdditions.h
//  JournlerCore
//
//  Created by Philip Dow on 6/10/06.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <Cocoa/Cocoa.h>

typedef UInt32 RichTextToHTMLOptions;
enum RichTextToHTML {
	kUseJournlerHTMLConversion = 0,
	kUseSystemHTMLConversion = 1 << 1,
	kUseInlineStyleDefinitions = 1 << 2,
	kConvertSmartQuotesToRegularQuotes = 1 << 3
};

@class JournlerEntry;
@class JournlerJournal;

@interface NSAttributedString (JournlerAdditions)

/*!
	@function attributedStringWithoutTextAttachments
	@abstract Returns an autoreleased copy of the receiver with the text attachments stripped
	@discussion Checks each character in the string for the NSAttachmentAttributeName attribute
		and deletes those characters from it. This method is similar to NSText's RTFFromRange
		covering the entire range of the string.
	@result NSAttributedString autoreleased copy of the receiver with no text attachments
*/

- (NSAttributedString*) attributedStringWithoutTextAttachments;

/*!
	@function attributedStringWithoutJournlerLinks
	@abstract Returns an autoreleased copy of the receiver with the journler links stripped
	@discussion Journler links are the those which the Journler application is registered to
		handle, in the form of journler:// . They are the URI representation of journler objects.
		These links are meaningless when used in an operating environment other than the user's own.
		Methods that export an entry to be read on another computer for example 
		will find this method useful.
		
		The method scans for NSLinkAttributeName attributes and strips it when the string or url
		corresponds to a journler object.
	@result NSAttributedString autoreleased copy of the receiver with the journler links removed.
*/

- (NSAttributedString*) attributedStringWithoutJournlerLinks;

/*!
	@function iPodLinkedNote:
	@abstract Returns an autoreleased string copy of the receiver suitable for viewing as an iPod note
	@discussion The method converts journler entry links in the receiver to links that work on an iPod.
		It uses the name and unique id of the entry for the linked text.
	@param aJournal the Journal which will be used to conver the Journler links to actual objects
		from which titles and unique ids can be derived.
	@result NSString a string representation of the receiver suitable for storage and display as an iPod note.
*/

- (NSString*) iPodLinkedNote:(JournlerJournal*)aJournal;

/*!
	@function firstImageData:fileType:
	@abstract Returns the data representation of the first image text attachment in the receiver
	@discussion Scans the receiver for the NSAttachmentAttributeName and tries to initialize an image
		with the associated data. Upon the first success returns the data representation of the image 
		in the formatspecified.
	@param aRange The range over which the method will scan the receiver.
	@param fileType The kind of data to return. See the NSBitmapImageFileType enumeration for more info
	@result NSData The data representation of the first image text attachment in the receiver,
		in the format specified.
*/

- (NSData*) firstImageData:(NSRange)aRange fileType:(NSBitmapImageFileType)type;

/*!
	@function attributedStringAsHTML:documentAttributes:avoidStyleAttributes:
	@abstract Returns an html representation of the receiver.
	@discussion Returns an html or xhtml/css represenation of the receiver. Attachments attributes
		are stripped. The html representation may or may not be a complete html document depending
		on the options specified.
	@param options See RichTextToHTMLOptions for more info. You may specify a system xhtml conversion
		with style attributes or Journler's own html conversion without. 
		Smart quotes may be converted to regular quotes. For the system conversion you may specify
		inline style attributes.
	@param documentAttributes NSDictionary of document attributes to be used by the system converter.
		See the NSAtributedString dataFromRange:documentAttributes:error: method for more information
	@param noList A NSString comma separated list of css style attributes that will be exluded from the 
		final xhtml representation when the system conversion is specified. For example, if you
		don't want font or line attributes specified -- as the system converter automatically includes them --
		pass @"font,line" to the method. 
		
		If a more abstract attribute is included in the list, all sub attributes are also filtered out.
		For example, if you specify "font" then css style attributes such as font, font-family, font-size
		and so on are all removed from the final html representation.
	@result NSString html representation of the receiver 
*/

- (NSString*) attributedStringAsHTML:(RichTextToHTMLOptions)options 
		documentAttributes:(NSDictionary*)docAttrs 
		avoidStyleAttributes:(NSString*)noList;
/*
	The following two functions provide the specific implementations for the 
		attributedStringAsHTML:documentAttributes:avoidStyleAttributes: method. See the discussion
		there for more information on how these methods work and what their parameters are.
		
		More specifically, _htmlWithInlineStyleDefinitions:bannedStyleAttributes: embeds style attributes
		that are defined at the top of an html document, replacing the class attribute on the objects 
		in the process.
*/

- (NSString*) _htmlUsingJournlerConverter;
- (NSString*) _htmlWithInlineStyleDefinitions:(NSString*)html bannedStyleAttributes:(NSString*)noList;

@end
