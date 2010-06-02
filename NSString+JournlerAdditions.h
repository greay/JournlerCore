//
//  NSString+JournlerAdditions.h
//  JournlerCore
//
//  Created by Philip Dow on 10/19/07.
//  Copyright Sprouted. All rights reserved.
//	All inquiries should be directed to developer@journler.com
//

#import <Cocoa/Cocoa.h>


@interface NSString (JournlerAdditions)

- (NSString*) journlerMD5Digest;
// would like to refactor this method out
// it's here because the utilities framework method MD5Digest wasn't working

@end
