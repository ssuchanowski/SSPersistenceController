//  Created by Sebastian Suchanowski (@ssuchanowski, www.synappse.co)

@import Foundation;
@import CoreData;

typedef void (^InitCallbackBlock)(void);
typedef void(^DBSaveCompletionBlock)(BOOL suceeded, NSError *error);

@interface SSPersistenceController : NSObject

@property (strong, readonly) NSManagedObjectContext *managedObjectContext;

- (instancetype)initWithModelName:(NSString *)modelName callback:(InitCallbackBlock)callback;
- (NSManagedObjectContext *)newPrivateChildManagedObjectContext;

/*
 * Perform save on main context and forward data for private context to do the operation
 */
- (void)save:(DBBooleanCompletionBlock)callback;

/*
 * Removes Persistent Store Coordinator
 */
- (void)cleanDatabase:(DBBooleanCompletionBlock)callback;

@end