//  Created by Sebastian Suchanowski (@ssuchanowski, www.synappse.co)

#import "SSPersistenceController.h"

@interface SSPersistenceController ()

@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
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

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(mom, @"NSManagedObjectModel not created correctly!");

    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSAssert(self.persistentStoreCoordinator, @"NSPersistenStoreCoordinator not created correctly!");

    [self setManagedObjectContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType]];

    [self setPrivateContext:[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]];
    [self.privateContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    [self.managedObjectContext setParentContext:[self privateContext]];

    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
        options[NSInferMappingModelAutomaticallyOption] = @YES;

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", modelName]];

        NSError *error = nil;
        NSPersistentStore *persistentStore = [weakSelf.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
        NSAssert(persistentStore, @"NSPersistentStoreCoordinator not added correctly!");

        if (![weakSelf initCallback]) {
            return;
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf initCallback]();
        });
    });
}

- (NSManagedObjectContext *)newPrivateChildManagedObjectContext {
    NSManagedObjectContext *bgManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    bgManagedObjectContext.parentContext = self.managedObjectContext;
    return bgManagedObjectContext;
}

- (void)save:(DBBooleanCompletionBlock)callback {

    __weak __typeof(self) weakSelf = self;
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf save:callback];
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
        if ([weakSelf.managedObjectContext save:&error]) {
            [weakSelf.privateContext performBlock:^{
                NSError *privateError = nil;
                if ([weakSelf.privateContext save:&privateError]) {
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
    [self.managedObjectContext reset];

    NSArray *stores = [[self.persistentStoreCoordinator persistentStores] copy];
    for (NSPersistentStore *store in stores) {
        NSError *error = nil;

        // iOS9 only method
        if ([self.persistentStoreCoordinator respondsToSelector:@selector(destroyPersistentStoreAtURL:withType:options:error:)]) {
            [self.persistentStoreCoordinator destroyPersistentStoreAtURL:store.URL withType:NSSQLiteStoreType options:nil error:&error];
        } else {
            [self.persistentStoreCoordinator removePersistentStore:store error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[store.URL.path stringByAppendingString:@"-wal"] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[store.URL.path stringByAppendingString:@"-shm"] error:&error];
        }

        if (callback) callback(error == nil, error);
    }

    self.managedObjectContext = nil;
    self.privateContext = nil;
    self.persistentStoreCoordinator = nil;

    [self initWithModelName:self.modelName callback:nil];
}

@end