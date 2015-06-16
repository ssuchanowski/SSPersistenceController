//  Created by Sebastian Suchanowski (@ssuchanowski, www.synappse.co)

@import Foundation;
@import CoreData;

@interface NSManagedObjectContext (SSAdditions)

- (NSArray *)fetchAllEntities:(Class)entityClass withPredicate:(NSPredicate *)predicate withSorting:(NSSortDescriptor *)sort fetchLimit:(NSUInteger)limit prefetchRelations:(NSArray *)prefetchRelations fetchProperties:(NSArray *)properties;
- (NSManagedObject *)fetchEntity:(Class)entityClass withPredicate:(NSPredicate *)predicate prefetchRelations:(NSArray *)prefetchRelations;
- (NSInteger)countAllEntities:(Class)entityClass withPredicate:(NSPredicate *)predicate;

- (NSManagedObject *)insertNewObject:(Class)entityClass;

@end