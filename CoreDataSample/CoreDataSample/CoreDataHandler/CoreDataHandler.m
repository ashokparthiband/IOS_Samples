//
//  CoreDataHandler.h
//  CoreDataSample
//
//  Created by Ashok Parthiban D on 19/02/18.
//  Copyright © 2018 Ashok Parthiban D. All rights reserved.
//

#import "CoreDataHandler.h"
#include <pthread.h>

@interface CoreDataHandler ()

@property (strong, nonatomic) NSManagedObjectContext *mainManagedObjectContext;

@end

@implementation CoreDataHandler

@synthesize managedObjectModel         = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


+(CoreDataHandler *)sharedInstance
{
    static CoreDataHandler *sharedInstance = nil;
    static dispatch_once_t pred;
    
    if (nil != sharedInstance)
        return sharedInstance;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[CoreDataHandler alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    return self;
}

- (NSManagedObjectContext *)mainManagedObjectContext {
    
    {
        if (_mainManagedObjectContext != nil) {
            return _mainManagedObjectContext;
        }
        
        
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (!coordinator) {
            return nil;
        }
        
        
        
        _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainManagedObjectContext setPersistentStoreCoordinator:coordinator];
        
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSaveMainQueueContext:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
    }
    
    
    return _mainManagedObjectContext;
}

#pragma mark - Notifications

- (void)contextDidSavePrivateQueueContext:(NSNotification *)notification
{
    
    //NSLog(@"\n\n\n\nn\n ---------- contextDidSavePrivateQueueContext  %@ \n\n\n\nn\n ----------",notification.object);
    if(_mainManagedObjectContext != notification.object)
    {
        @synchronized(self) {
            [_mainManagedObjectContext performBlock:^{
                [_mainManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                [_mainManagedObjectContext save:nil];
            }];
        }
    }
}

- (void)contextDidSaveMainQueueContext:(NSNotification *)notification
{
    if(_mainManagedObjectContext != notification.object)
    {
        {
            [_mainManagedObjectContext performBlockAndWait:^{
                @try {
                    [_mainManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                    [_mainManagedObjectContext save:nil];
                }
                @catch (NSException * exception){
                    NSLog(@"Core Data Handler Crash : %@",exception);
                }
            }];
        }
    }
    if(self.managedObjectContext  != notification.object)
    {
        @synchronized(self)
        {
            [self.managedObjectContext performBlock:^{
                @try {
                    if(![NSThread isMainThread])
                    {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                        });
                    }
                    else
                    {
                        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                    }
                }
                @catch (NSException * exception){
                    NSLog(@"Core Data Handler Crash : %@",exception);
                }
            }];
        }
    }
}



- (NSManagedObjectContext *)managedObjectContext {
    
    
    NSThread *currentThread = [NSThread currentThread];
    
    NSManagedObjectContext * context = [[currentThread threadDictionary] objectForKey:@"managedObjectContext"];
    if (context != nil && context.parentContext  && context.parentContext == self.mainManagedObjectContext) {
        return context;
    }
    
    
    
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setParentContext:self.mainManagedObjectContext];
    
    [[currentThread threadDictionary] setObject:context forKey:@"managedObjectContext"];
    return context;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    
    @synchronized (self) {
        
        
        if (_persistentStoreCoordinator != nil) {
            return _persistentStoreCoordinator;
        }
        
        // Create the coordinator and store
        
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

        NSError *error              = nil;
        
        
        NSURL * directoryUrl =[NSURL URLWithString:[NSString stringWithFormat:@"%@DataBase/", [self applicationDocumentsDirectory]]];
        BOOL isDirectory;
        if(![[NSFileManager defaultManager] fileExistsAtPath:[directoryUrl path] isDirectory:&isDirectory])
        {
            [[NSFileManager defaultManager] createDirectoryAtURL:directoryUrl withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSURL * storeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@DataBase/CoreDataSample.sqlite", [self applicationDocumentsDirectory]]];
        NSLog(@"WiSeConnectDB \n\n\n %@ \n\n\n",storeURL);

        NSString *failureReason = @"There was an error creating or loading the application's saved data.";
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            // Report any error we got.
            NSMutableDictionary *dict              = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey]        = @"Failed to initialize the application's saved data";
            dict[NSLocalizedFailureReasonErrorKey] = failureReason;
            dict[NSUnderlyingErrorKey]             = error;
            error                                  = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }

    NSURL *modelURL     = [[NSBundle bundleForClass:[self class]] URLForResource:@"CoreDataSample" withExtension:@"momd"];
    
//    NSURL *modelURL     = [[NSBundle bundleForClass:[self class]] URLForResource:@"CoreDataSample" withExtension:@"xcdatamodeld"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

-(NSManagedObject*)getNewEntity:(NSString*)entityName
{
    return  [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
}

-(NSEntityDescription*)getEntity:(NSString*)entityName
{
    return  [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
}

-(void)deleteEntity:(NSManagedObject*)entity
{
    if(entity && ![entity isDeleted])
    {
        [self.managedObjectContext deleteObject:entity];
        [self saveContext];
        
    }
    else
    {
        NSLog(@"cannot delete empty object from managedObjectContxet");
    }
}

-(void)deleteEntityByObjectID:(NSManagedObjectID*)entityID
{
    if (entityID)
    {
        NSManagedObject *deleteObject =[self getObjectForId:entityID];
        if (deleteObject)
        {
            [self.managedObjectContext deleteObject:deleteObject];
            
        }
        else
        {
            NSLog(@"\n\n\n\n----------could not delete empty object from managedObjectContxet");
        }
        
    }
    
}

- (NSManagedObject*)getObjectForId :(NSManagedObjectID*)objectId
{
    NSManagedObject *managedObject = nil;
    if(objectId)
    {
        NSError *error = nil;
        managedObject  = [self.managedObjectContext existingObjectWithID:objectId error:&error];
        if (error) {
            managedObject = nil;
        }
    }
    return managedObject;
}

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.cdata.CoreDataDemo" in the application's documents directory.
    //NSDocumentDirectory
    //NSCachesDirectory
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


- (NSArray *)fetchDataWithentityName : (NSString *)entityName
                           predicate : (NSPredicate *)predicate
                     sortDescriptors : (NSArray<NSSortDescriptor *> *)sortDescriptors
                               start : (int)start
                               limit : (int)limit
{
    NSArray *result;
    @try {
        NSError * error = nil;
        
        NSManagedObjectContext * managedObjectContext = [[CoreDataHandler sharedInstance] managedObjectContext];
        NSFetchRequest *fetchRequest                  = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity                   = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
        [fetchRequest setEntity:entity];
        
        if(predicate)
        {
            [fetchRequest setPredicate:predicate];
        }
        if(sortDescriptors && [sortDescriptors count])
        {
            [fetchRequest setSortDescriptors:sortDescriptors];
            
            if(sortDescriptors && [sortDescriptors count] && start >= 0)
            {
                [fetchRequest setFetchOffset:start];
            }
        }
        
        if(limit>0)
        {
            [fetchRequest setFetchLimit:limit];
        }
        else
        {
            limit = 10000;
        }

        result = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        //NSLog(@"result \n\n\n\n---------------------\n\n\n\n %@ \n\n\n\n---------------------\n\n\n\n ", result );
        
    }
    @catch (NSException *exception) {
        NSLog(@"exception %@",exception);
    }
    @finally {
        
    }
    
    return result;
}

- (NSInteger) fetchCountForEntity : (NSString *) entityName
                    withPredicate : (NSPredicate *) predicate
{
    NSInteger count = 0;
    @try {
        NSError * error = nil;
        NSManagedObjectContext * managedObjectContext = [[CoreDataHandler sharedInstance] managedObjectContext];
        NSFetchRequest *fetchRequest                  = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity                   = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
        [fetchRequest setEntity:entity];
        if(predicate) [fetchRequest setPredicate:predicate];
        count = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
    }
    @catch (NSException *exception) {
        NSLog(@"exception %@",exception);
    }
    @finally {
        
    }
    
    return count;
}

- (NSArray *)fetchDataWithentityName : (NSString *)entityName
               propertiesToBeFetched : (NSArray *) propertiesToBeFetchedArray
                           predicate : (NSPredicate *)predicate
                     sortDescriptors : (NSArray *)sortDescriptors
                               start : (int)start
                               limit : (int)limit
{
    NSArray *result;
    @try {
        NSError * error = nil;
        
        NSManagedObjectContext * managedObjectContext = [[CoreDataHandler sharedInstance] managedObjectContext];
        NSFetchRequest *fetchRequest                  = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity                   = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
        [fetchRequest setEntity:entity];
        
        if (propertiesToBeFetchedArray && propertiesToBeFetchedArray.count)
        {
            [fetchRequest setPropertiesToFetch:propertiesToBeFetchedArray];
            [fetchRequest setResultType:NSDictionaryResultType];
        }
        
        if(predicate)
        {
            [fetchRequest setPredicate:predicate];
        }
        if(sortDescriptors && [sortDescriptors count])
        {
            [fetchRequest setSortDescriptors:sortDescriptors];
            
            if(sortDescriptors && [sortDescriptors count] && start >= 0)
            {
                [fetchRequest setFetchOffset:start];
            }
        }
        
        if(limit>0)
        {
            [fetchRequest setFetchLimit:limit];
        }
        else
        {
            limit = 10000;
        }
        
        result = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
    }
    @catch (NSException *exception) {
        NSLog(@"exception %@",exception);
    }
    @finally {
        
    }
    
    return result;
}

-(void)saveContext
{
    @try {
        
        if (self.managedObjectContext != nil)
        {
            NSError *error = nil;
            if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
            {
                
                
            }
            else
            {
//                [_mainManagedObjectContext performBlockAndWait:^{
//                    [_mainManagedObjectContext save:nil];
//                }];
            }
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"exception %@",exception);
    }
    @finally {
        
    }
    
}

- (void)deleteDatabase
{
    @try {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSManagedObjectContext *mainManagedObjectContexttemp = _mainManagedObjectContext;
        _mainManagedObjectContext                            = nil;
        
        
        // @synchronized(self.deleteObj)
        {
            [mainManagedObjectContexttemp reset];
            [_persistentStoreCoordinator removePersistentStore:[[_persistentStoreCoordinator persistentStores] firstObject] error:nil];
            mainManagedObjectContexttemp = nil;
            _managedObjectModel          = nil;
            _persistentStoreCoordinator  = nil;
            NSURL * sqlitePathUrl        = [NSURL URLWithString:[NSString stringWithFormat:@"%@DataBase/", [self applicationDocumentsDirectory]]];
            [[NSFileManager defaultManager] removeItemAtURL:sqlitePathUrl error:nil];
            
        }
        
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
    
}

@end
