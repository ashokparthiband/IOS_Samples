//
//  UserManager.m
//  CoreDataSample
//
//  Created by Ashok Parthiban D on 19/02/18.
//  Copyright © 2018 Ashok Parthiban D. All rights reserved.
//

#import "UserManager.h"
#import "CoreDataHandler.h"
#import "EntityUser+CoreDataProperties.h"
#import "UserModel.h"

#define UserEntity "EntityUser"

@implementation UserManager
{
    CoreDataHandler * dbHandler;
}

- (instancetype)init {
    if (self = [super init]) {
        dbHandler = [CoreDataHandler sharedInstance];
    }
    return self;
}

- (void) addUser : (NSArray <UserModel *> *) users {
    for (UserModel * user in users) {
        EntityUser * dbObject = (EntityUser *)[dbHandler getNewEntity :@UserEntity];
        dbObject.name         = user.name;
        dbObject.userId       = user.userId;
        dbObject.age          = user.age;
        dbObject.sex          = user.sex;
        [dbHandler saveContext];
    }
}

- (NSArray <UserModel *>*) getUsers
{
    NSMutableArray * arrUsers = [[NSMutableArray alloc] init];
    NSArray * result          = [dbHandler fetchDataWithentityName :@UserEntity predicate :nil sortDescriptors :nil start :0 limit :0];
    for (EntityUser * dbObject in result) {
        UserModel * model = [[UserModel alloc] init];
        model.name        = dbObject.name;
        model.userId      = (int)dbObject.userId;
        model.age         = dbObject.age;
        model.sex         = dbObject.sex;
        [arrUsers addObject:model];
    }
    return [arrUsers mutableCopy];
}

@end
