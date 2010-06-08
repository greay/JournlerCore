//
//  NSURL+JournlerAdditions.h
//  JournlerCore
//
//  Created by Philip Dow on 6/7/06.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <Cocoa/Cocoa.h>
#import <JournlerCore/Definitions.h>

@interface NSURL (JournlerAdditions)

/*!
	@function isJournlerURI
	@abstract Returns true if the receiver represents a journler object.
	@discussion The receiver's scheme will be "journler", a url in the form of journler://x/y
		where x identifies the object's class and y the object's unique identifier.
		See the URIRepresentation method on JournlerObject for more information about Journler urls.
	@result YES if the receiver represents a Journler object, NO otherwise.
*/

- (BOOL) isJournlerURI;

/*!
	@function isJournlerHelpURI
	@abstract Returns true if the receiver represents a Journler help link
	@discussion Journler embeds links to its help files inside the first laucnh default entries 
		so that a user can quickly access more information about the topics covered. Help URIs
		are in the form of journler://help/x where x is a help anchor defined in the help files.
	@result YES if the receiver represents a Journler help anchor, NO otherwise.
*/

- (BOOL) isJournlerHelpURI;

/*!
	@function isJournlerLicenseURI
	@abstract Returns true if the receiver represents a Journler license
	@discussion I briefly entertained the idea of distributing licenses in a url format so that
		the user would not have to type in the name and code manually. I still think it's a neat
		idea, but it sure does simplify piracy. Journler license urls are in the form
		journler://license/name/code
	@result YES if the receiver represents a Journler license url, NO otherwise.
*/

- (BOOL) isJournlerLicenseURI;

/*!
	@function isJournlerEntry
	@abstract Returns true if the receiver represents a Journler entry
	@discussion Checks the scheme and host of the url, should be in the format journler://entry/x
		where x is the entry's unique id. URLs in this format are handled by Journler and so can
		be embedded in other documents on the user's computer.
	@result YES if the receiver represents a Journler entry, NO otherwise.
*/

- (BOOL) isJournlerEntry;

/*!
	@function isJournlerResource
	@abstract Returns true if the receiver represents a Journler resource
	@discussion Checks the scheme and host of the url, should be in the format journler://reference/x
		where x is the resources's unique id. URLs in this format are handled by Journler and so can
		be embedded in other documents on the user's computer. 
		
		Note that resources were for a brief
		time referred to as "references". The reason for the peculiar host name is more that 
		journler://resource/x urls were used in earlier versions of Journler to represent resources 
		in a different way, not based on unique id but actual filenames I believe. The host was
		changed to differentiate between the old and new formats.
	@result YES if the receiver represents a Journler resource, NO otherwise.
*/

- (BOOL) isJournlerResource;

/*!
	@function isJournlerFolder
	@abstract Returns true if the receiver represents a Journler folder
	@discussion Checks the scheme and host of the url, should be in the format journler://folder/x
		where x is the folders's unique id. URLs in this format are handled by Journler and so can
		be embedded in other documents on the user's computer.
	@result YES if the receiver represents a Journler folder, NO otherwise.
*/

- (BOOL) isJournlerFolder;

/*!
	@function isAddressBookUID
	@abstract Returns true if the receiver represents an address book record
	@discussion The method is deprecated. Do not use it. Before Journler stored references
		to address book contacts in the format defined by the AB framework, it implemented
		its own means of referencing theme. URLs of this kind are in the format of 
		AddressBookUID://uid.
	@result YES if the receiver represents address book record in a journler proprietary way, NO otherwise.
*/

- (BOOL) isAddressBookUID JOURNLER_DEPRECATED;

/*!
	@function isPhotoID
	@abstract Returns true if the receiver represents an iPhoto photo
	@discussion The method is deprecated. Do not use it. For a brief time Journler allowed users
		to link directly to iPhoto photos. I'm not even sure how the process worked. URLs of this kind
		are in the format iPhotoID://something...
	@result YES if the receiver represents an iPhoto photo in a journler proprietary way, NO otherwise.
*/

- (BOOL) isPhotoID JOURNLER_DEPRECATED;

/*!
	@function isOldJournlerResource
	@abstract Returns true if the receiver represents an old journler resource
	@discussion The method is deprecated. Do not use it. For a brief time Journler stored links
		to attached files using the actual filename rather than the unique id of the object wrapping
		the resource. In fact I don't think the journal even had an object to represent attached files.
		URLs of this kind are in the journler://resource/filename format, which is the reason why 
		"reference" is now used for the hostname instead of the more appropriate resource.
	@result YES if the receiver represents an old Journler resource, NO otherwise.
*/

- (BOOL) isOldJournlerResource JOURNLER_DEPRECATED;

/*!
	@function isHTTP
	@abstract Returns true if the receiver represents an http location
	@discussion Checks the scheme to see if it is "http". Case insensitive. shttp schemes
		return NO.
	@result YES if the receiver represents an http location, NO otherwise.
*/

- (BOOL) isHTTP;

@end
