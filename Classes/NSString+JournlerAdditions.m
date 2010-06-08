//
//  NSString+JournlerAdditions.m
//  JournlerCore
//
//  Created by Philip Dow on 10/19/07.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <JournlerCore/NSString+JournlerAdditions.h>
#import <SproutedUtilities/SproutedUtilities.h>
#include <openssl/md5.h>

@implementation NSString (JournlerAdditions)

- (NSString*) journlerMD5Digest 
{	
	NSString *returnString = nil;
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	if ( data ) 
	{
		NSMutableData *digest = [NSMutableData dataWithLength:MD5_DIGEST_LENGTH];
		if ( digest && MD5([data bytes], [data length], [digest mutableBytes])) {
			NSString *digestAsString = [digest description];
			returnString = digestAsString;
		}
	}
	
	return returnString;
}


@end
