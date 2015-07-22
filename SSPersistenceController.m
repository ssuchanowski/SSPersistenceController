//  Created by Sebastian Suchanowski (@ssuchanowski, www.synappse.co)

#import "SSPersistenceController.h"

@interface SSPersistenceController ()

@property (strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (strong) NSManagedObjectContext *privateContext;

@property (copy) InitCallbackBlock initCallback;

@end

@implementation SSPersistenceController

- (instancetype)initWithModelName:(NSString *)modelName callback:(InitCallbackBlock)callback {
    if (!(self = [super init])) return nil;

    [self setInitCallback:callback];
    [self initializeCoreDataWithModelName:modelName];

    return self;
}

- (void)initializeCoreDataWithModelName:(NSString *)modelName {
    if (self.managedObjectContext) {
        return;
    }

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(mom, @"NSManagedObjectModel not created correctly!");

    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSAssert(coordinator, @"NSPersistenStoreCoordinator not created correctly!");

    [self setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType]];

    [self setPrivateContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
    [self.privateContext setPersistentStoreCoordinator:coordinator];
    [self.managedObjectContext setParentContext:[self privateContext]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSPersistentStoreCoordinator *psc = [[self privateContext] persistentStoreCoordinator];
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
        options[NSInferMappingModelAutomaticallyOption] = @YES;

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", modelName]];

        NSError *error = nil;
        NSPersistentStore *persistentStore = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
        NSAssert(persistentStore, @"NSPersistentStoreCoordinator not added correctly!");

        if (![self initCallback]) {
            return;
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            [self initCallback]();
        });
    });
}

- (NSManagedObjectContext *)newPrivateChildManagedObjectContext {
    NSManagedObjectContext *bgManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    bgManagedObjectContext.parentContext = self.managedObjectContext;
    return bgManagedObjectContext;
}

- (void)save:(DBSaveCompletionBlock)callback {

    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self save:callback];
        });
        return;
    }

    if (![self.managedObjectContext hasChanges] && ![self.privateContext hasChanges]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) callback(YES, nil);
        });
        return;
    }

    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        if ([self.managedObjectContext save:&error]) {
            [self.privateContext performBlock:^{
                NSError *privateError = nil;
                if ([self.privateContext save:&privateError]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) callback(YES, nil);
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) callback(NO, privateError);
                    });
                }
            }];
        } else {
            if (callback) callback(NO, error);
        }
    }];
}

- (void)cleanDatabase:(DBBooleanCompletionBlock)callback {
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext reset];
        NSArray *stores = [self.managedObjectContext.persistentStoreCoordinator persistentStores];
        for (NSPersistentStore *store in stores) {
            NSError *error = nil;
            [self.managedObjectContext.persistentStoreCoordinator removePersistentStore:store error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:&error];
            if (callback) {
                self.managedObjectContext = nil;
                callback(error == nil, error);
                // TODO: create it after
            }
        }
    }];
}

@end