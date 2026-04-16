//
//  YALCoreDataStack.m
//  MemoryCity
//
//  Created by Codex on 2026/4/11.
//

#import "YALCoreDataStack.h"

static NSString * const kYALPersistentContainerName = @"MemoryCityCache";
static NSString * const kYALCachedPostEntityName = @"YALCachedPost";

@implementation YALCoreDataStack

+ (instancetype)sharedStack {
    static YALCoreDataStack *stack;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stack = [[YALCoreDataStack alloc] initPrivate];
    });
    return stack;
}

- (instancetype)init {
    [NSException raise:@"YALCoreDataStackInitError"
                format:@"Use +[YALCoreDataStack sharedStack] instead."];
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _persistentContainer = [[NSPersistentContainer alloc] initWithName:kYALPersistentContainerName
                                                      managedObjectModel:[self managedObjectModel]];
        NSPersistentStoreDescription *description = _persistentContainer.persistentStoreDescriptions.firstObject;
        description.shouldMigrateStoreAutomatically = YES;
        description.shouldInferMappingModelAutomatically = YES;

        [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull storeDescription, NSError * _Nullable error) {
            (void)storeDescription;
            (void)error;
        }];

        _persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        _persistentContainer.viewContext.automaticallyMergesChangesFromParent = YES;
        _persistentContainer.viewContext.name = @"YALViewContext";
    }
    return self;
}

- (NSManagedObjectContext *)viewContext {
    return self.persistentContainer.viewContext;
}

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext *context))block {
    if (!block) {
        return;
    }
    [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * _Nonnull context) {
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        context.name = @"YALBackgroundContext";
        block(context);
    }];
}

- (void)saveViewContextIfNeeded {
    NSManagedObjectContext *context = self.viewContext;
    if (!context.hasChanges) {
        return;
    }

    [context performBlock:^{
        NSError *error = nil;
        [context save:&error];
    }];
}

#pragma mark - Model

- (NSManagedObjectModel *)managedObjectModel {
    NSEntityDescription *cachedPostEntity = [[NSEntityDescription alloc] init];
    cachedPostEntity.name = kYALCachedPostEntityName;
    cachedPostEntity.managedObjectClassName = @"NSManagedObject";

    NSMutableArray<NSAttributeDescription *> *attributes = [NSMutableArray array];
    [attributes addObject:[self stringAttributeWithName:@"cacheScope"]];
    [attributes addObject:[self stringAttributeWithName:@"cacheKey"]];
    [attributes addObject:[self integer64AttributeWithName:@"sortOrder"]];
    [attributes addObject:[self stringAttributeWithName:@"payloadJSON"]];
    [attributes addObject:[self stringAttributeWithName:@"contentIdString"]];
    [attributes addObject:[self stringAttributeWithName:@"titleText"]];
    [attributes addObject:[self stringAttributeWithName:@"contentText"]];
    [attributes addObject:[self stringAttributeWithName:@"cityText"]];
    [attributes addObject:[self stringAttributeWithName:@"yearText"]];
    [attributes addObject:[self stringAttributeWithName:@"moodText"]];
    [attributes addObject:[self stringAttributeWithName:@"imagesJSON"]];
    [attributes addObject:[self stringAttributeWithName:@"createTimeText"]];
    [attributes addObject:[self stringAttributeWithName:@"imageURLString"]];
    [attributes addObject:[self stringAttributeWithName:@"locationNameText"]];
    [attributes addObject:[self stringAttributeWithName:@"authorUserIdString"]];
    [attributes addObject:[self stringAttributeWithName:@"authorNicknameText"]];
    [attributes addObject:[self stringAttributeWithName:@"authorAvatarText"]];
    [attributes addObject:[self stringAttributeWithName:@"authorBioText"]];
    [attributes addObject:[self boolAttributeWithName:@"isPublicValue"]];
    [attributes addObject:[self boolAttributeWithName:@"isLikedValue"]];
    [attributes addObject:[self boolAttributeWithName:@"isCollectedValue"]];
    [attributes addObject:[self integer64AttributeWithName:@"likeCountValue"]];
    [attributes addObject:[self integer64AttributeWithName:@"collectCountValue"]];
    [attributes addObject:[self integer64AttributeWithName:@"commentCountValue"]];
    [attributes addObject:[self doubleAttributeWithName:@"latitudeValue"]];
    [attributes addObject:[self doubleAttributeWithName:@"longitudeValue"]];
    [attributes addObject:[self dateAttributeWithName:@"updatedAt"]];
    cachedPostEntity.properties = attributes;

    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    model.entities = @[cachedPostEntity];
    return model;
}

- (NSAttributeDescription *)stringAttributeWithName:(NSString *)name {
    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
    attribute.name = name;
    attribute.attributeType = NSStringAttributeType;
    attribute.optional = YES;
    return attribute;
}

- (NSAttributeDescription *)integer64AttributeWithName:(NSString *)name {
    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
    attribute.name = name;
    attribute.attributeType = NSInteger64AttributeType;
    attribute.optional = NO;
    attribute.defaultValue = @(0);
    return attribute;
}

- (NSAttributeDescription *)boolAttributeWithName:(NSString *)name {
    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
    attribute.name = name;
    attribute.attributeType = NSBooleanAttributeType;
    attribute.optional = NO;
    attribute.defaultValue = @(NO);
    return attribute;
}

- (NSAttributeDescription *)doubleAttributeWithName:(NSString *)name {
    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
    attribute.name = name;
    attribute.attributeType = NSDoubleAttributeType;
    attribute.optional = NO;
    attribute.defaultValue = @(0.0);
    return attribute;
}

- (NSAttributeDescription *)dateAttributeWithName:(NSString *)name {
    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
    attribute.name = name;
    attribute.attributeType = NSDateAttributeType;
    attribute.optional = YES;
    return attribute;
}

@end
