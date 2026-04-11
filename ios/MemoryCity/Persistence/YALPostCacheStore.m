//
//  YALPostCacheStore.m
//  MemoryCity
//
//  Created by Codex on 2026/4/11.
//

#import "YALPostCacheStore.h"

#import <CoreData/CoreData.h>

#import "YALCoreDataStack.h"
#import "YALPostModel.h"

static NSString * const kYALCachedPostEntityName = @"YALCachedPost";
static NSString * const kYALHomeFeedCacheScope = @"home_feed";
static NSString * const kYALDetailCacheScope = @"content_detail";
static NSString * const kYALFavoriteCacheScopePrefix = @"favorites";

@implementation YALPostCacheStore

+ (instancetype)sharedStore {
    static YALPostCacheStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[YALPostCacheStore alloc] init];
    });
    return store;
}

- (void)fetchHomeFeedPostsWithCompletion:(void (^)(NSArray<YALPostModel *> *posts))completion {
    if (!completion) {
        return;
    }

    [[YALCoreDataStack sharedStack] performBackgroundTask:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kYALCachedPostEntityName];
        request.predicate = [NSPredicate predicateWithFormat:@"cacheScope == %@", kYALHomeFeedCacheScope];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES]];

        NSError *error = nil;
        NSArray<NSManagedObject *> *records = [context executeFetchRequest:request error:&error];
        if (error) {
            NSLog(@"❌ Fetch cached home feed failed: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(@[]);
            });
            return;
        }

        NSMutableArray<YALPostModel *> *posts = [NSMutableArray arrayWithCapacity:records.count];
        for (NSManagedObject *record in records) {
            YALPostModel *model = [self postModelFromRecord:record];
            if (model) {
                [posts addObject:model];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion([posts copy]);
        });
    }];
}

- (void)replaceHomeFeedPosts:(NSArray<YALPostModel *> *)posts
                  completion:(void (^ _Nullable)(NSError * _Nullable error))completion {
    [[YALCoreDataStack sharedStack] performBackgroundTask:^(NSManagedObjectContext *context) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kYALCachedPostEntityName];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"cacheScope == %@", kYALHomeFeedCacheScope];

        NSError *error = nil;
        NSArray<NSManagedObject *> *existingRecords = [context executeFetchRequest:fetchRequest error:&error];
        if (error) {
            NSLog(@"❌ Query existing cached home feed failed: %@", error);
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error);
                });
            }
            return;
        }

        for (NSManagedObject *record in existingRecords) {
            [context deleteObject:record];
        }

        NSInteger sortOrder = 0;
        for (YALPostModel *post in posts) {
            NSManagedObject *record = [NSEntityDescription insertNewObjectForEntityForName:kYALCachedPostEntityName inManagedObjectContext:context];
            [record setValue:kYALHomeFeedCacheScope forKey:@"cacheScope"];
            [record setValue:[NSString stringWithFormat:@"%@_%ld", kYALHomeFeedCacheScope, (long)sortOrder] forKey:@"cacheKey"];
            [record setValue:@(sortOrder) forKey:@"sortOrder"];
            [self fillRecord:record withPostModel:post];
            sortOrder += 1;
        }

        NSError *saveError = nil;
        if ([context hasChanges] && ![context save:&saveError]) {
            NSLog(@"❌ Save cached home feed failed: %@", saveError);
        }

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(saveError);
            });
        }
    }];
}

- (void)fetchContentDetailWithId:(NSNumber *)contentId
                      completion:(void (^)(NSDictionary * _Nullable content))completion {
    if (!completion) {
        return;
    }

    if (contentId.integerValue <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
        return;
    }

    NSString *cacheKey = [self detailCacheKeyForContentId:contentId];
    [[YALCoreDataStack sharedStack] performBackgroundTask:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kYALCachedPostEntityName];
        request.fetchLimit = 1;
        request.predicate = [NSPredicate predicateWithFormat:@"cacheScope == %@ AND cacheKey == %@", kYALDetailCacheScope, cacheKey];

        NSError *error = nil;
        NSArray<NSManagedObject *> *records = [context executeFetchRequest:request error:&error];
        NSDictionary *payload = nil;
        if (!error && records.count > 0) {
            payload = [self dictionaryFromJSONString:[records.firstObject valueForKey:@"payloadJSON"]];
        } else if (error) {
            NSLog(@"❌ Fetch cached detail failed: %@", error);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(payload);
        });
    }];
}

- (void)cacheContentDetail:(NSDictionary *)content
                 contentId:(NSNumber *)contentId
                completion:(void (^ _Nullable)(NSError * _Nullable error))completion {
    if (contentId.integerValue <= 0 || ![content isKindOfClass:[NSDictionary class]]) {
        if (completion) {
            completion(nil);
        }
        return;
    }

    NSString *cacheKey = [self detailCacheKeyForContentId:contentId];
    [[YALCoreDataStack sharedStack] performBackgroundTask:^(NSManagedObjectContext *context) {
        NSManagedObject *record = [self existingRecordForScope:kYALDetailCacheScope
                                                     cacheKey:cacheKey
                                                      context:context];
        if (!record) {
            record = [NSEntityDescription insertNewObjectForEntityForName:kYALCachedPostEntityName inManagedObjectContext:context];
            [record setValue:kYALDetailCacheScope forKey:@"cacheScope"];
            [record setValue:cacheKey forKey:@"cacheKey"];
            [record setValue:@(0) forKey:@"sortOrder"];
        }

        [record setValue:[self jsonStringFromDictionary:content] forKey:@"payloadJSON"];
        [record setValue:[self safeStringFromNumber:contentId] forKey:@"contentIdString"];
        [record setValue:[NSDate date] forKey:@"updatedAt"];

        NSError *saveError = nil;
        if ([context hasChanges] && ![context save:&saveError]) {
            NSLog(@"❌ Save cached detail failed: %@", saveError);
        }

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(saveError);
            });
        }
    }];
}

- (void)fetchFavoritePostsForUserId:(NSNumber *)userId
                         completion:(void (^)(NSArray<YALPostModel *> *posts))completion {
    if (!completion) {
        return;
    }

    NSString *scope = [self favoriteCacheScopeForUserId:userId];
    [[YALCoreDataStack sharedStack] performBackgroundTask:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kYALCachedPostEntityName];
        request.predicate = [NSPredicate predicateWithFormat:@"cacheScope == %@", scope];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES]];

        NSError *error = nil;
        NSArray<NSManagedObject *> *records = [context executeFetchRequest:request error:&error];
        NSMutableArray<YALPostModel *> *posts = [NSMutableArray array];
        if (error) {
            NSLog(@"❌ Fetch cached favorites failed: %@", error);
        } else {
            for (NSManagedObject *record in records) {
                YALPostModel *model = [self postModelFromRecord:record];
                if (model) {
                    [posts addObject:model];
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion([posts copy]);
        });
    }];
}

- (void)replaceFavoritePosts:(NSArray<YALPostModel *> *)posts
                      userId:(NSNumber *)userId
                  completion:(void (^ _Nullable)(NSError * _Nullable error))completion {
    NSString *scope = [self favoriteCacheScopeForUserId:userId];
    [[YALCoreDataStack sharedStack] performBackgroundTask:^(NSManagedObjectContext *context) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kYALCachedPostEntityName];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"cacheScope == %@", scope];

        NSError *error = nil;
        NSArray<NSManagedObject *> *existingRecords = [context executeFetchRequest:fetchRequest error:&error];
        if (error) {
            NSLog(@"❌ Query cached favorites failed: %@", error);
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error);
                });
            }
            return;
        }

        for (NSManagedObject *record in existingRecords) {
            [context deleteObject:record];
        }

        NSInteger sortOrder = 0;
        for (YALPostModel *post in posts) {
            NSManagedObject *record = [NSEntityDescription insertNewObjectForEntityForName:kYALCachedPostEntityName inManagedObjectContext:context];
            [record setValue:scope forKey:@"cacheScope"];
            NSString *contentIdString = [self safeStringFromNumber:post.contentId];
            NSString *cacheKey = contentIdString.length > 0 ? contentIdString : [NSString stringWithFormat:@"row_%ld", (long)sortOrder];
            [record setValue:cacheKey forKey:@"cacheKey"];
            [record setValue:@(sortOrder) forKey:@"sortOrder"];
            [self fillRecord:record withPostModel:post];
            sortOrder += 1;
        }

        NSError *saveError = nil;
        if ([context hasChanges] && ![context save:&saveError]) {
            NSLog(@"❌ Save cached favorites failed: %@", saveError);
        }

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(saveError);
            });
        }
    }];
}

- (void)removeFavoritePostWithContentId:(NSNumber *)contentId
                                 userId:(NSNumber *)userId
                             completion:(void (^ _Nullable)(NSError * _Nullable error))completion {
    if (contentId.integerValue <= 0) {
        if (completion) {
            completion(nil);
        }
        return;
    }

    NSString *scope = [self favoriteCacheScopeForUserId:userId];
    NSString *cacheKey = [self safeStringFromNumber:contentId];
    [[YALCoreDataStack sharedStack] performBackgroundTask:^(NSManagedObjectContext *context) {
        NSManagedObject *record = [self existingRecordForScope:scope cacheKey:cacheKey context:context];
        if (record) {
            [context deleteObject:record];
        }

        NSError *saveError = nil;
        if ([context hasChanges] && ![context save:&saveError]) {
            NSLog(@"❌ Remove cached favorite failed: %@", saveError);
        }

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(saveError);
            });
        }
    }];
}

#pragma mark - Mapping

- (void)fillRecord:(NSManagedObject *)record withPostModel:(YALPostModel *)post {
    [record setValue:[self safeStringFromNumber:post.contentId] forKey:@"contentIdString"];
    [record setValue:[self jsonStringFromDictionary:[self dictionaryFromPostModel:post]] forKey:@"payloadJSON"];
    [record setValue:[self safeString:post.title] forKey:@"titleText"];
    [record setValue:[self safeString:post.content] forKey:@"contentText"];
    [record setValue:[self safeString:post.city] forKey:@"cityText"];
    [record setValue:[self safeString:post.year] forKey:@"yearText"];
    [record setValue:[self safeString:post.mood] forKey:@"moodText"];
    [record setValue:[self jsonStringFromImages:post.images] forKey:@"imagesJSON"];
    [record setValue:[self safeString:post.createTime] forKey:@"createTimeText"];
    [record setValue:[self safeString:post.imageURLString] forKey:@"imageURLString"];
    [record setValue:[self safeString:post.locationName] forKey:@"locationNameText"];
    [record setValue:[self safeStringFromNumber:post.authorUserId] forKey:@"authorUserIdString"];
    [record setValue:[self safeString:post.authorNickname] forKey:@"authorNicknameText"];
    [record setValue:[self safeString:post.authorAvatar] forKey:@"authorAvatarText"];
    [record setValue:[self safeString:post.authorBio] forKey:@"authorBioText"];
    [record setValue:@(post.isPublic) forKey:@"isPublicValue"];
    [record setValue:@(post.isLiked) forKey:@"isLikedValue"];
    [record setValue:@(post.isCollected) forKey:@"isCollectedValue"];
    [record setValue:@(post.likeCount) forKey:@"likeCountValue"];
    [record setValue:@(post.collectCount) forKey:@"collectCountValue"];
    [record setValue:@(post.commentCount) forKey:@"commentCountValue"];
    [record setValue:@(post.latitude) forKey:@"latitudeValue"];
    [record setValue:@(post.longitude) forKey:@"longitudeValue"];
    [record setValue:[NSDate date] forKey:@"updatedAt"];
}

- (nullable YALPostModel *)postModelFromRecord:(NSManagedObject *)record {
    YALPostModel *post = [[YALPostModel alloc] init];
    post.contentId = [self numberFromString:[record valueForKey:@"contentIdString"]];
    post.title = [self safeString:[record valueForKey:@"titleText"]];
    post.content = [self safeString:[record valueForKey:@"contentText"]];
    post.desc = post.content;
    post.city = [self safeString:[record valueForKey:@"cityText"]];
    post.year = [self safeString:[record valueForKey:@"yearText"]];
    post.mood = [self safeString:[record valueForKey:@"moodText"]];
    post.images = [self imagesFromJSONString:[record valueForKey:@"imagesJSON"]];
    post.createTime = [self safeString:[record valueForKey:@"createTimeText"]];
    post.imageURLString = [self safeString:[record valueForKey:@"imageURLString"]];
    if (post.imageURLString.length == 0) {
        post.imageURLString = post.images.firstObject ?: @"";
    }
    post.locationName = [self safeString:[record valueForKey:@"locationNameText"]];
    post.authorUserId = [self numberFromString:[record valueForKey:@"authorUserIdString"]];
    post.authorNickname = [self safeString:[record valueForKey:@"authorNicknameText"]];
    post.authorAvatar = [self safeString:[record valueForKey:@"authorAvatarText"]];
    post.authorBio = [self safeString:[record valueForKey:@"authorBioText"]];
    post.isPublic = [[record valueForKey:@"isPublicValue"] boolValue];
    post.isLiked = [[record valueForKey:@"isLikedValue"] boolValue];
    post.isCollected = [[record valueForKey:@"isCollectedValue"] boolValue];
    post.likeCount = [[record valueForKey:@"likeCountValue"] integerValue];
    post.collectCount = [[record valueForKey:@"collectCountValue"] integerValue];
    post.commentCount = [[record valueForKey:@"commentCountValue"] integerValue];
    post.latitude = [[record valueForKey:@"latitudeValue"] doubleValue];
    post.longitude = [[record valueForKey:@"longitudeValue"] doubleValue];

    if (@available(iOS 13.0, *)) {
        post.image = [UIImage systemImageNamed:@"photo"];
    } else {
        post.image = [[UIImage alloc] init];
    }
    post.imageWidth = 300.0;
    post.imageHeight = 400.0;
    return post;
}

- (NSDictionary *)dictionaryFromPostModel:(YALPostModel *)post {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (post.contentId.integerValue > 0) {
        dict[@"content_id"] = post.contentId;
    }
    dict[@"title"] = [self safeString:post.title];
    dict[@"content"] = [self safeString:post.content];
    dict[@"city"] = [self safeString:post.city];
    dict[@"year"] = [self safeString:post.year];
    dict[@"mood"] = [self safeString:post.mood];
    dict[@"images"] = post.images ?: @[];
    dict[@"create_time"] = [self safeString:post.createTime];
    dict[@"location_name"] = [self safeString:post.locationName];
    dict[@"is_public"] = @(post.isPublic);
    dict[@"is_liked"] = @(post.isLiked);
    dict[@"is_collected"] = @(post.isCollected);
    dict[@"like_count"] = @(post.likeCount);
    dict[@"collect_count"] = @(post.collectCount);
    dict[@"comment_count"] = @(post.commentCount);
    dict[@"latitude"] = @(post.latitude);
    dict[@"longitude"] = @(post.longitude);
    if (post.authorUserId.integerValue > 0) {
        dict[@"user_id"] = post.authorUserId;
    }
    if (post.authorNickname.length > 0) {
        dict[@"nickname"] = post.authorNickname;
    }
    if (post.authorAvatar.length > 0) {
        dict[@"avatar"] = post.authorAvatar;
    }
    if (post.authorBio.length > 0) {
        dict[@"bio"] = post.authorBio;
    }
    return [dict copy];
}

- (NSString *)safeString:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    return @"";
}

- (NSString *)safeStringFromNumber:(NSNumber *)value {
    if ([value respondsToSelector:@selector(stringValue)]) {
        return value.stringValue ?: @"";
    }
    return @"";
}

- (nullable NSNumber *)numberFromString:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length > 0) {
            return @([text integerValue]);
        }
    }
    return nil;
}

- (NSString *)jsonStringFromImages:(NSArray<NSString *> *)images {
    if (![images isKindOfClass:[NSArray class]] || images.count == 0) {
        return @"[]";
    }
    return [self jsonStringFromJSONObject:images fallback:@"[]"];
}

- (NSString *)jsonStringFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]] || dictionary.count == 0) {
        return @"{}";
    }
    return [self jsonStringFromJSONObject:dictionary fallback:@"{}"];
}

- (NSString *)jsonStringFromJSONObject:(id)object fallback:(NSString *)fallback {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (!data || error) {
        return fallback ?: @"";
    }
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return json ?: fallback ?: @"";
}

- (NSArray<NSString *> *)imagesFromJSONString:(id)value {
    if (![value isKindOfClass:[NSString class]]) {
        return @[];
    }
    NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return @[];
    }
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![object isKindOfClass:[NSArray class]]) {
        return @[];
    }

    NSMutableArray<NSString *> *images = [NSMutableArray array];
    for (id item in (NSArray *)object) {
        if ([item isKindOfClass:[NSString class]] && [((NSString *)item) length] > 0) {
            [images addObject:item];
        }
    }
    return [images copy];
}

- (NSDictionary *)dictionaryFromJSONString:(id)value {
    if (![value isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return (NSDictionary *)object;
}

- (NSManagedObject *)existingRecordForScope:(NSString *)scope
                                   cacheKey:(NSString *)cacheKey
                                    context:(NSManagedObjectContext *)context {
    if (scope.length == 0 || cacheKey.length == 0) {
        return nil;
    }
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kYALCachedPostEntityName];
    request.fetchLimit = 1;
    request.predicate = [NSPredicate predicateWithFormat:@"cacheScope == %@ AND cacheKey == %@", scope, cacheKey];
    NSError *error = nil;
    NSArray<NSManagedObject *> *records = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"❌ Query cached record failed: %@", error);
        return nil;
    }
    return records.firstObject;
}

- (NSString *)detailCacheKeyForContentId:(NSNumber *)contentId {
    return [NSString stringWithFormat:@"detail_%@", [self safeStringFromNumber:contentId]];
}

- (NSString *)favoriteCacheScopeForUserId:(NSNumber *)userId {
    NSInteger resolvedUserId = MAX(userId.integerValue, 0);
    return [NSString stringWithFormat:@"%@_%ld", kYALFavoriteCacheScopePrefix, (long)resolvedUserId];
}

@end
