//  Created by Sebastian Suchanowski (@ssuchanowski, www.synappse.co)

@import Foundation;
@import CoreData;

@interface NSManagedObjectContext (SSAdditions)

- (NSArray *)fetchAllEntities:(Class)entityClass withPredicate:(NSPredicate *)predicate;
- (NSArray *)fetchAllEntities:(Class)entityClass withPredicate:(NSPredicate *)predicate withSorting:(NSArray *)sortDescriptors;
- (NSArray *)fetchAllEntities:(Class)entityClass withPredicate:(NSPredicate *)predicate withSorting:(NSArray *)sortDescriptors fetchLimit:(NSUInteger)limit;
- (NSArray *)fetchAllEntities:(Class)entityClass withPredicate:(NSPredicate *)predicate withSorting:(NSArray *)sortDescriptors fetchLimit:(NSUInteger)limit prefetchRelations:(NSArray *)prefetchRelations;
- (NSArray *)fetchAllEntities:(Class)entityClass withPredicate:(NSPredicate *)predicate withSorting:(NSArray *)sortDescriptors fetchLimit:(NSUInteger)limit prefetchRelations:(NSArray *)prefetchRelations fetchProperties:(NSArray *)properties;

- (NSManagedObject *)fetchEntity:(Class)entityClass withPredicate:(NSPredicate *)predicate;
- (NSManagedObject *)fetchEntity:(Class)entityClass withPredicate:(NSPredicate *)predicate withSorting:(NSArray *)sortDescriptors;
- (NSManagedObject *)fetchEntity:(Class)entityClass withPredicate:(NSPredicate *)predicate withSorting:(NSArray *)sortDescriptors prefetchRelations:(NSArray *)prefetchRelations;
- (NSManagedObject *)fetchEntity:(Class)entityClass withPredicate:(NSPredicate *)predicate withSorting:(NSArray *)sortDescriptors prefetchRelations:(NSArray *)prefetchRelations fetchProperties:(NSArray *)properties;

- (NSInteger)countAllEntities:(Class)entityClass withPredicate:(NSPredicate *)predicate;

- (NSManagedObject *)insertNewObject:(Class)entityClass;

@end