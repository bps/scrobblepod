//
//  BGLastFMPasswordChecker.h
//  ScrobblePod
//
//  Created by Ben on 8/02/08.
//  Copyright 2008 Ben Gummer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BGLastFMPasswordChecker : NSObject {

}
-(BOOL)checkCredentialsWithUsername:(NSString *)theUsername andPassword:(NSString *)thePassword;
@end
