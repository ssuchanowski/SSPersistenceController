//  Created by Sebastian Suchanowski (@ssuchanowski, www.synappse.co)

#import "NSManagedObjectContext+SSAdditions.h"
#import "NSManagedObject+SSAdditions.h"
#import "KZAsserts.h"

@implementation NSManagedObjectContext (SSAdditions)

#pragma mark - Fetching

- (NSArray *)fetchAllEntities:(Class)entityClass
                withPredicate:(NSPredicate *)predicate
                  withSorting:(NSArray *)sortDescriptors
                   fetchLimit:(NSUInteger)limit
            prefetchRelations:(NSArray *)prefetchRelations
              fetchProperties:(NSArray *)properties {

    AssertTrueOrReturnNil([entityClass isSubclassOfClass:[NSManagedObject class]]);

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[entityClass entityClassName]];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = limit;
    fetchRequest.propertiesToFetch = properties;
    fetchRequest.includesPendingChanges = YES;
    fetchRequest.sortDescriptors = sortDescriptors;
    if (prefetchRelations) {
        [fetchRequest setRelationshipKeyPathsForPrefetching:prefetchRelations];
    }

    NSError *error = nil;
    NSArray *fetched = [self executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"Error while fetching entities (%@) - %@", [entityClass entityClassName], error.localizedDescription);
        fetched = nil;
    }

    return fetched;
}

- (NSManagedObject *)fetchEntity:(Class)entityClass
                   withPredicate:(NSPredicate *)predicate
                     withSorting:(NSArray *)sortDescriptors
               prefetchRelations:(NSArray *)prefetchRelations {

    AssertTrueOrReturnNil([entityClass isSubclassOfClass:[NSManagedObject class]]);

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[entityClass entityClassName]];
    fetchRequest.includesPendingChanges = YES;
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;
    fetchRequest.sortDescriptors = sortDescriptors;

    if (prefetchRelations) {
        [fetchRequest setRelationshipKeyPathsForPrefetching:prefetchRelations];
    }

    NSError *error = nil;
    NSArray *fetchResult = [self executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"Error while fetching entity (%@) - %@", [entityClass entityClassName], error.localizedDescription);
    } else if (fetchResult.count >= 1) {
        return fetchResult[0];
    }

    return nil;
}

- (NSInteger)countAllEntities:(Class)entityClass withPredicate:(NSPredicate *)predicate {
    AssertTrueOr([entityClass isSubclassOfClass:[NSManagedObject class]], return -1;);

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[entityClass entityClassName]];
    fetchRequest.predicate = predicate;

    NSError *error = nil;
    NSUInteger result = [self countForFetchRequest:fetchRequest error:&error];
    if (!error) {
        return result;
    }

    return -1;
}

#pragma mark - Inserting

- (NSManagedObject *)insertNewObject:(Class)entityClass {
    AssertTrueOrReturnNil([entityClass isSubclassOfClass:[NSManagedObject class]]);

    return [NSEntityDescription insertNewObjectForEntityForName:[entityClass entityClassName] inManagedObjectContext:self];
}

#pragma mark - Deleting

@end