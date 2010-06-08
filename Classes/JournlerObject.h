//
//  JournlerObject.h
//  JournlerCore
//
//  Created by Philip Dow on 1/26/07.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

/*!
	@header JournlerObject
	@abstract Implements the base class for objects stored in a Journal
	@discussion See the class discussion.
 */

/*!
	@class JournlerObject
	@abstract The base clase for all objects managed by the JournlerJournal.
	@discussion JournlerObject is an abstract class that provides a limited amount
		of shared functionality for its various subclasses. All the objects
		managed by a journal are subclassed from JournlerObject. If you are 
		familiar with CoreData, you can thik of the JournlerObject as NSManagedObject
		and the JournlerJournal as the NSManagedObjectContext, with limitations.
		
		JournlerObject and its subclasses support the NSCopying and NSCoding protocols.
		The objects may be copied and archived for disk based storage.
		
		JournlerObject is an abstract class. You should not create instances of 
		JournlerObject in your code. Instead use JournlerEntry and JournlerResource
		for example.
*/

#import <Cocoa/Cocoa.h>

#define JournlerObjectDidChangeValueForKeyNotification @"JournlerObjectDidChangeAttributeNotification"
#define JournlerObjectAttributeKey @"JournlerObjectAttributeKey"
#define JournlerObjectAttributeLabelKey @"label"

@class JournlerJournal;

@interface JournlerObject : NSObject <NSCopying, NSCoding> {
	
	NSMutableDictionary	 *_properties;
	
	JournlerJournal *_journal;
	
	NSNumber *_dirty;
	NSNumber *_deleted;
	
	id _scriptContainer;
}

/*!
	@function initWithProperties:
	@abstract Initializes the receiver with a dictionary of key/value pairs 
		corresponding to the receiver's instance variables.
	@discussion initWithProperties is the default initializer for the JournlerObject.
		Subclasses must call method when they are initialized.
	@param aDictionary A dictionary of key-value pairs corresponding to the attributes supported by the receiver.
	@result A JournlerObject initialized with the key/value pairs contained in aDictionary.
*/

- (id) initWithProperties:(NSDictionary*)aDictionary;

/*!
	@function properties
	@abstract returns the receiver's properties, a dictionary of key/value pairs corresponding to the object's instance variables.
	@discussion 
	@result An NSDictionary with key-value pairs corresponding to the instance variables supported by the receiver.
		Normally you should not need to call this method. 
		Instead access the receiver's values using the provided accessors.
*/

- (NSDictionary*) properties;

/*!
	@function setProperties
	@abstract sets the receiver's properties.
	@discussion This method sets the receivers properties, replacing all of the individual values supported by the receiver.
		You should not call this method directly. 
		Instead use the setters provided by the receiver such as setTitle: and setIcon:
		Many setters provide additional functionality so that modifying the corresponding value
		in the properties dictionary would result in inconsistenties across a journal's ojects. 
		
		Journler objects do not maintain invididual instance variables for their various attributes.
		All of an object's attributes are stored in a single NSDictinonary which is accessed and updated
		by the various getters and setters. The mechanism is handled internally by the API and should
		not normally affect your use of the JournlerObject and its subclasses.
	@param aDictionary A dictionary of keyvalue pairs corresponding to the attributes supported by the receiver.
*/

- (void) setProperties:(NSDictionary*)aDictionary;

/*	--
	@function defaultProperties
	@abstract Returns the default properties for the receiver
	@discussion Subclasses override this method to provide the default attributes
		for new instances. The method is used by initWithProperties:.
*/

+ (NSDictionary*) defaultProperties;

#pragma mark -

/*!
	@function journal
	@abstract Returns the journal associated with the receiver.
	@discussion Every JournlerObject is associated with a specific journal, 
		a relationship rather than a property. The journal manages the receiver
		and its relationship with other objects in the journal such as entries, folders and resources.
		See also setJournal:.
	@result The journal responsible for managing the receiver. See JournlerJournal.
*/

- (JournlerJournal*) journal;

/*!
	@function setJournal:
	@abstract Sets the journal associated with the receiver.
	@discussion Every JournlerObject is associated with a specific journal, 
		a relationship rather than a property. The journal manages the receiver
		and its relationship with other objects in the journal such as entries, folders and resources.
		You should not need to call this method. The framework handles the relationship between a 
		journal and its objects internally.
		See also journal.
	@param aJournal The journal you would like to attach this object to.
*/

- (void) setJournal:(JournlerJournal*)aJournal;

/*!
	@function journalID
	@abstract Returns the journal identifier for this object
	@discussion Every object in the JournlerJournal object graph belongs to a single
		journal. During runtime the journal is identified directly using the 
		journal and setJournal: methods. When an object in the graph is archived, 
		Journler stores the journal's numeric id along with the object.
		
		The journal id is a sufficiently unique value based on the machine's time
		when the journal was initially created. In the future the journal id may
		be used to identify which journal of a number a given archived object belongs to.
		Currently only a single journal database is supported.
	@result NSNumber set true or false
*/

- (NSNumber*) journalID;

/*!
	@function journalID
	@abstract Sets the unique journal identifier for the object
	@discussion See the discussion at journalID. You should not need to call this method.
	@param aNumber unique id associated with the journal
*/

- (void) setJournalID:(NSNumber*)aNumber;

/*!
	@function dirty
	@abstract Identifies the receiver as having unsaved data
	@discussion When the attributes or relationships of an object are changed
		the dirty property is marked true. When the journal is saved all
		dirty objects are written to disk and the attribute is marked false.
		You should not need to call this method. The dirty state is maintained internally.
	@result NSNumber set true or false
	@see -[JournlerJournal identifier]
*/

#pragma mark -

- (NSNumber*) dirty;

/*!
	@function setDirty:
	@abstract Identifies the receiver as having unsaved data
	@discussion See discussion at dirty.
	@param aNumber NSNumber set to true or false
*/

- (void) setDirty:(NSNumber*)aNumber;

/*!
	@function deleted
	@abstract Identifies the receiver as having been deleted
	@discussion An object is marked deleted when it has been removed from the journal.
		Although the object has been removed from the object graph it may remain
		in memory for some time. The JournlerJournal object checks this attribute
		before writing dirty objects to disk on which it sill has a hold.
	@result NSNumber set true or false
*/

- (NSNumber*) deleted;

/*!
	@function setDeleted:
	@abstract Identifies the receiver as having been deleted
	@discussion See discussion at deleted.
	@param aNumber NSNumber set to true or false
*/

- (void) setDeleted:(NSNumber*)aNumber;

#pragma mark -

/*!
	@function tagID
	@abstract Returns the object's unique numeric identifier
	@discussion Every object in a journal is identified numerically. The number is 
		unique to objects of that class and will not be repeated even as objects are deleted.
		Objects are only unique to the journal. The system for creating new tagIDs is
		simple: start at zero and increment the count by 1 each time an object of that
		class is created.
		
		If you create new objects in code it is generally your responsibility to set the new tagID.
		However, if you do not, when you add the object to the journal using methods such as
		addEntry:, addCollection: and addResource: the journal assigns a new unique tag.
		See the JournlerJournal methods newEntryTag, newFolderTag and newResourceTag.
	@result NSNumber that uniquely identifies this object among objects of the same class
*/

- (NSNumber*) tagID;

/*!
	@function setTagID:
	@abstract Sets the object's unique numeric identifier
	@discussion See discussion at tagID.
	@param aNumber NSNumber that uniquely identifies this object among objects of the same class
*/

- (void) setTagID:(NSNumber*)aNumber;

/*!
	@function title
	@abstract The object's title or name
	@discussion Every object in a journal be it a folder, entry or resource has a
		title. The title is displayed to the user for his or her benefit and does
		not uniquely identify the object.
	@result NSNumber set true or false
*/

- (NSString*) title;

/*!
	@function setTitle:
	@abstract Sets object's title or name
	@discussion See discussion at title
	@param aString The string to which the object's title will be set.
*/

- (void) setTitle:(NSString*)aString;

/*!
	@function icon
	@abstract The object's visual representation
	@discussion An object's icon visually identifies the object to the user and is used
		in a number of locations in the interface: when folders are listed, resource
		thumbnails, menu representations and so on. A user can customize a folder's icon, 
		while a resource's icon depends on the contents. A single icon is shared by every entry.
	@result NSImage The object's icon.
*/

- (NSImage*) icon;

/*!
	@function setIcon:
	@abstract Sets the object's visual representation
	@discussion See discussion at icon
	@param anImage The image to which the object's icon will be set.
*/

- (void) setIcon:(NSImage*)anImage;

#pragma mark -

/*!
	@function scriptContainer
	@abstract Returns the object in the scripting hierarchy which contains the receiver
	@discussion In all cases the scriptContainer is the application object
	@result id The scripting object which contains the receiver
*/

- (id) scriptContainer;

/*!
	@function setScriptContainer:
	@abstract Sets the scripting object which contains the receiver
	@discussion In all cases the script contains is the application object. You should not
		need to call this method. The scriptContainer is set automatically when an object
		is created.
	@param anObject The scripting object which contains the receiver
*/

- (void) setScriptContainer:(id)anObject;

/*!
	@function objectSpecifier
	@abstract Returns the NSScriptObjectSpecifier which maps the scripting language to the object graph
	@discussion Subclasses override this method to identify themselves to the scripting system.
		Folders, entries and resources all identify themselves by unique id relative to the application object.
	@result NSScriptObjectSpecifier An object which allows the scripting system to map
		the language of scripts to the object graph.
*/

- (NSScriptObjectSpecifier *)objectSpecifier;

#pragma mark -

/*!
	@function hash
	@abstract Returns an integer that can be used as a table address in a hash table structure (dev documentation)
	@discussion The Journler Object builds the hash from the object's tagID which is immutable 
		and unique to objects of the same class
	@result NSUInteger that can be used as a table address in a hash table structure (dev documentation).
*/

- (NSUInteger) hash;

/*!
	@function isEqual:
	@abstract Returns a Boolean value that indicates whether the receiver and a given object are equal (dev documentation).
	@discussion The JournlerEntry and JournlerCollection objects make the test based on class participation
		and the object's unique id. The JournlerResource does the same but makes an addition to account for
		temporary resources that are created on the fly. For these it checks the URI representation as well.
	@param anObject The object to be compared to the receiver
	@result BOOL YES if the receiver and anObject are equal, otherwise NO (dev documentation).
*/

- (BOOL) isEqual:(id)anObject;

/*!
	@function pathSafeTitle
	@abstract Returns a file system safe version of the object's title.
	@discussion A path safe string is one in which colons and forward slashes have been replaced
		with dashes.
	@result NSString The object's path safe title.
*/

- (NSString*) pathSafeTitle;

/*!
	@function URIRepresentation
	@abstract Returns a representation of the object in the form of a uniform resource identifier 
	@discussion An object's URI uniquely identifies that object in an application and platform
		independent way. The URL takes the form of journler://object-type/object-id and may be
		embedded in the text of other applications. Journler registers itself as the handler for 
		the journler scheme. In this way the URI not only uniquely identifies an object in the
		object graph but also allows other applications to refer to Journler objects.
	@result NSURL The objects URI representation as an NSURL object.
*/

- (NSURL*) URIRepresentation;

/*!
	@function URIRepresentationAsString
	@abstract Returns a representation of the object in the form of a uniform resource identifier 
	@discussion Returns the URI representation as a string instead of a URL. For more information
		refer to the URIRepresentation method.
	@result NSString The objects URI representation as an NSString object.
*/

- (NSString*) URIRepresentationAsString;

/*!
	@function menuItemRepresentation:
	@abstract Returns a menu representation of the object
	@discussion The menu representation includes the objects icon and title. No keyEquivalent is set.
		You will need to set target, action and representedObject information if you plan to use them.
	@param imageSize the image size to use for the menu item, for example 32x32.
	@result NSString The objects URI representation as an NSString object.
*/

- (NSMenuItem*) menuItemRepresentation:(NSSize)imageSize;

#pragma mark -

// keys used for the tag and title, subclasses may override

+ (NSString*) tagIDKey;
+ (NSString*) titleKey;
+ (NSString*) iconKey;

#pragma mark -

- (NSArray*) keyPathsAffectingDirty;

- (void) startObserveringKeyPathsAffectingDirty;
- (void) stopObserveringKeyPathsAffectingDirty;

@end