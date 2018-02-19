
//
//  CoreDataHandler.h
//  CoreDataSample
//
//  Created by Ashok Parthiban D on 19/02/18.
//  Copyright © 2018 Ashok Parthiban D. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface CoreDataHandler : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext       *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel         *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


+(CoreDataHandler *)sharedInstance;

- (NSURL *)applicationDocumentsDirectory;

-(NSManagedObject*)getNewEntity:(NSString*)entityName;
-(NSEntityDescription*)getEntity:(NSString*)entityName;

- (void)saveContext;

-(void)deleteEntity:(NSManagedObject*)entity;
-(void)deleteEntityByObjectID:(NSManagedObjectID*)entityID;
- (void)deleteDatabase;

- (NSArray *)fetchDataWithentityName : (NSString *)entityName
                           predicate : (NSPredicate *)predicate
                     sortDescriptors : (NSArray *)sortDescriptors
                               start : (int)start
                               limit : (int)limit;

- (NSArray *)fetchDataWithentityName : (NSString *)entityName
               propertiesToBeFetched : (NSArray *) propertiesToBeFetchedArray
                           predicate : (NSPredicate *)predicate
                     sortDescriptors : (NSArray *)sortDescriptors
                               start : (int)start
                               limit : (int)limit;

- (NSInteger) fetchCountForEntity : (NSString *) entityName
                    withPredicate : (NSPredicate *) predicate;

@end
