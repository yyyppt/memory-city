//
//  YALCoreDataStack.h
//  MemoryCity
//
//  Created by Codex on 2026/4/11.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALCoreDataStack : NSObject

@property (nonatomic, strong, readonly) NSPersistentContainer *persistentContainer;
@property (nonatomic, strong, readonly) NSManagedObjectContext *viewContext;

+ (instancetype)sharedStack;

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext *context))block;
- (void)saveViewContextIfNeeded;

@end

NS_ASSUME_NONNULL_END
