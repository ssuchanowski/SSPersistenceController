@import Foundation;
@import CoreData;

typedef void (^InitCallbackBlock)(void);
typedef void(^DBSaveCompletionBlock)(BOOL suceeded, NSError *error);

@interface SSPersistenceController : NSObject

@property (strong, readonly) NSManagedObjectContext *managedObjectContext;

- (instancetype)initWithModelName:(NSString *)modelName callback:(InitCallbackBlock)callback;
- (NSManagedObjectContext *)newChildPrivateManagedObjectContext;
- (void)save:(DBSaveCompletionBlock)callback;

@end