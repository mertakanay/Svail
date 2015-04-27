//
//  User.h
//  Svail
//
//  Created by Ronald Hernandez on 4/13/15.
//  Copyright (c) 2015 Svail. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "Verification.h"

//@class Verification;

@interface User : PFUser<PFSubclassing>

@property NSString *state;
@property NSString *city;
@property NSString *name;
@property NSString *occupation;
@property NSString *phoneNumber;
@property PFFile *profileImage;
@property NSString *specialty;
@property NSString *gender;
@property BOOL isFbUser;
@property (nonatomic) Verification *verification;

//-(void)getVerificationRecordWithCompletion:(void (^)())complete;

@end
