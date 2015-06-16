//  Created by Sebastian Suchanowski (@ssuchanowski, www.synappse.co)

#import "NSManagedObject+SSAdditions.h"

@implementation NSManagedObject (SSAdditions)

+ (NSString *)entityClassName {
    return NSStringFromClass(self);
}

@end