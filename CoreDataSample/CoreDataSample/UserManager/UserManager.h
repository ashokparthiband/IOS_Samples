//
//  UserManager.h
//  CoreDataSample
//
//  Created by Ashok Parthiban D on 19/02/18.
//  Copyright © 2018 Ashok Parthiban D. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UserModel;

@interface UserManager : NSObject

- (void) addUser : (NSArray <UserModel *> *) users;

- (NSArray <UserModel *>*) getUsers;

@end
