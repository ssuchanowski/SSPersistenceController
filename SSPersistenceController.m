//  Created by Sebastian Suchanowski (@ssuchanowski, www.synappse.co)

#import "SSPersistenceController.h"

@interface SSPersistenceController ()

@property (strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (strong) NSManagedObjectContext *privateContext;
@property (strong) NSString *modelName;

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

    self.modelName = modelName;
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:[self modelURL]];
    NSAssert(mom, @"NSManagedObjectModel not created correctly!");

    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSAssert(coordinator, @"NSPersistenStoreCoordinator not created correctly!");

    [self setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType]];

    [self setPrivateContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
    [self.privateContext setPersistentStoreCoordinator:coordinator];
    [self.managedObjectContext setParentContext:[self privateContext]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSPersistentStoreCoordinator *psc = [[self privateContext] persistentStoreCoordinator];
        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption : @YES,
                                  NSInferMappingModelAutomaticallyOption : @YES,
                                  };
        
        NSError *error = nil;
        NSPersistentStore *persistentStore = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self storeURL] options:options error:&error];
        if (!persistentStore) {
            NSLog(@"NSPersistentStoreCoordinator not added correctly, resetting");
            __weak __typeof(self) weakSelf = self;
            [self cleanDatabase:^(BOOL suceeded, NSError *error) {
                NSAssert1(suceeded, @"Database clean failed: %@", error.localizedDescription);
            }];
            return;
        }
        
        if (![self initCallback]) {
            return;
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            [self initCallback]();
        });
    });
}

- (NSURL *)modelURL {
    return [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"momd"];
}

- (NSURL *)storeURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", self.modelName]];
}

- (NSManagedObjectContext *)newPrivateChildManagedObjectContext {
    NSManagedObjectContext *bgManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    bgManagedObjectContext.parentContext = self.managedObjectContext;
    return bgManagedObjectContext;
}

- (void)save:(DBBooleanCompletionBlock)callback {

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
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:[self storeURL] error:NULL];
    
    __weak __typeof(self) weakSelf = self;
    [self.managedObjectContext performBlockAndWait:^{
        __typeof__(self) strongSelf = weakSelf;
        
        [strongSelf.managedObjectContext reset];
        NSArray *stores = [strongSelf.managedObjectContext.persistentStoreCoordinator persistentStores];
        NSError *error = nil;
        for (NSPersistentStore *store in stores) {
            NSError *innerError = nil;
            [strongSelf.managedObjectContext.persistentStoreCoordinator removePersistentStore:store error:&innerError];
            [fileManager removeItemAtPath:store.URL.path error:&innerError];
            if (innerError) {
                error = innerError;
            }
        }
        strongSelf.managedObjectContext = nil;
        strongSelf.privateContext = nil;
        [strongSelf initWithModelName:strongSelf.modelName callback:^{
            if (callback) callback(error == nil, error);
        }];
    }];
}

@end