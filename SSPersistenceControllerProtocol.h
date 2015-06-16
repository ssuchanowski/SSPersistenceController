//  Created by Sebastian Suchanowski (@ssuchanowski, www.synappse.co)

@import Foundation;
@import CoreData;

@class SSPersistenceController;

@protocol SSPersistenceControllerProtocol <NSObject>
- (void)setPersistenceController:(SSPersistenceController *)persistenceController;
@end