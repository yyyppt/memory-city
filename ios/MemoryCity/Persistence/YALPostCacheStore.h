//
//  YALPostCacheStore.h
//  MemoryCity
//
//  Created by Codex on 2026/4/11.
//

#import <Foundation/Foundation.h>

@class YALPostModel;

NS_ASSUME_NONNULL_BEGIN

@interface YALPostCacheStore : NSObject

+ (instancetype)sharedStore;

- (void)fetchHomeFeedPostsWithCompletion:(void (^)(NSArray<YALPostModel *> *posts))completion;
- (void)replaceHomeFeedPosts:(NSArray<YALPostModel *> *)posts
                  completion:(void (^ _Nullable)(NSError * _Nullable error))completion;
- (void)fetchContentDetailWithId:(NSNumber *)contentId
                      completion:(void (^)(NSDictionary * _Nullable content))completion;
- (void)cacheContentDetail:(NSDictionary *)content
                 contentId:(NSNumber *)contentId
                completion:(void (^ _Nullable)(NSError * _Nullable error))completion;
- (void)fetchFavoritePostsForUserId:(NSNumber *)userId
                         completion:(void (^)(NSArray<YALPostModel *> *posts))completion;
- (void)replaceFavoritePosts:(NSArray<YALPostModel *> *)posts
                      userId:(NSNumber *)userId
                  completion:(void (^ _Nullable)(NSError * _Nullable error))completion;
- (void)removeFavoritePostWithContentId:(NSNumber *)contentId
                                 userId:(NSNumber *)userId
                             completion:(void (^ _Nullable)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
