//
//  YALPostManager.m
//  MemoryCity
//
//  Created by mac on 2026/3/23.
//
#import "YALPostManager.h"
#import "YALPostCacheStore.h"
#import "YALContentManager.h"

static NSString * _Nullable YALPostManagerFirstNonEmptyStringFromDictionary(NSDictionary *dict, NSArray<NSString *> *keys) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (text.length > 0) {
                return text;
            }
        }
    }
    return nil;
}

static NSString * _Nullable YALPostManagerFirstNonEmptyStringRecursively(id obj, NSArray<NSString *> *keys) {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSString *direct = YALPostManagerFirstNonEmptyStringFromDictionary((NSDictionary *)obj, keys);
        if (direct.length > 0) {
            return direct;
        }
        for (id value in [(NSDictionary *)obj allValues]) {
            NSString *nested = YALPostManagerFirstNonEmptyStringRecursively(value, keys);
            if (nested.length > 0) {
                return nested;
            }
        }
    } else if ([obj isKindOfClass:[NSArray class]]) {
        for (id value in (NSArray *)obj) {
            NSString *nested = YALPostManagerFirstNonEmptyStringRecursively(value, keys);
            if (nested.length > 0) {
                return nested;
            }
        }
    }
    return nil;
}

static BOOL YALPostManagerBoolValue(id value, BOOL fallback) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [((NSNumber *)value) integerValue] != 0;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [((NSString *)value) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) {
            return fallback;
        }
        NSString *lower = text.lowercaseString;
        if ([lower isEqualToString:@"1"] ||
            [lower isEqualToString:@"true"] ||
            [lower isEqualToString:@"yes"] ||
            [lower isEqualToString:@"public"] ||
            [lower isEqualToString:@"公开"]) {
            return YES;
        }
        if ([lower isEqualToString:@"0"] ||
            [lower isEqualToString:@"false"] ||
            [lower isEqualToString:@"no"] ||
            [lower isEqualToString:@"2"] ||
            [lower isEqualToString:@"private"] ||
            [lower isEqualToString:@"only_self"] ||
            [lower isEqualToString:@"self"] ||
            [lower isEqualToString:@"personal"] ||
            [lower isEqualToString:@"私密"] ||
            [lower isEqualToString:@"仅自己可见"]) {
            return NO;
        }
    }
    return fallback;
}

static BOOL YALPostManagerShouldShowPublicContent(NSDictionary *dict) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    id publicValue = dict[@"is_public"];
    if (!publicValue || publicValue == [NSNull null]) {
        return NO;
    }
    return YALPostManagerBoolValue(publicValue, NO);
}

@interface YALPostManager ()

@property (nonatomic, assign) NSInteger lastDisplayedHomeFeedPage;

@end

@implementation YALPostManager

- (NSArray<YALPostModel *> *)filteredPublicPostsFromPosts:(NSArray<YALPostModel *> *)posts {
    if (![posts isKindOfClass:[NSArray class]] || posts.count == 0) {
        return @[];
    }
    NSMutableArray<YALPostModel *> *filtered = [NSMutableArray array];
    for (YALPostModel *model in posts) {
        if (![model isKindOfClass:[YALPostModel class]]) {
            continue;
        }
        if (!model.isPublic) {
            continue;
        }
        [filtered addObject:model];
    }
    return [filtered copy];
}
                     
+ (instancetype)shareManager {
    static YALPostManager *postManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        postManager = [[YALPostManager alloc] init];
    });
    return postManager;
}

- (void)getPosts:(void(^)(NSArray<YALPostModel *> *posts, NSError *error))completion {
    [self getPostsWithCache:^(NSArray<YALPostModel *> * _Nullable posts, BOOL fromCache, NSError * _Nullable error) {
        if (fromCache) {
            return;
        }
        if (completion) {
            completion(posts, error);
        }
    }];
}

- (void)getPostsWithCache:(void(^)(NSArray<YALPostModel *> * _Nullable posts, BOOL fromCache, NSError * _Nullable error))completion {
    [[YALPostCacheStore sharedStore] fetchHomeFeedPostsWithCompletion:^(NSArray<YALPostModel *> *posts) {
        NSArray<YALPostModel *> *cachedPosts = [self filteredPublicPostsFromPosts:(posts ?: @[])];
        if (cachedPosts.count > 0) {
            if (completion) {
                completion(cachedPosts, YES, nil);
            }
        }

        [self requestLatestPostsWithCachedPosts:cachedPosts page:1 randomizePage:NO completion:completion];
    }];
}

- (void)refreshPostsWithRandomSample:(void(^)(NSArray<YALPostModel *> * _Nullable posts, NSError * _Nullable error))completion {
    [self fetchAllPublicPostsForRefreshWithCompletion:completion];
}

- (void)requestLatestPostsWithCachedPosts:(NSArray<YALPostModel *> *)cachedPosts
                                     page:(NSInteger)page
                            randomizePage:(BOOL)randomizePage
                               completion:(void(^)(NSArray<YALPostModel *> * _Nullable posts, BOOL fromCache, NSError * _Nullable error))completion {
    YALNetworkManager *manager = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/list", YALAPIBaseURLString];
    NSInteger const pageSize = 15;
    NSInteger requestedPage = MAX(page, 1);

    NSDictionary *parameters = @{
        @"page": @(requestedPage),
        @"size": @(pageSize)
    };

    [manager GET:url parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALPostManager" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Invalid response object"}];
                completion(nil, NO, error);
            }
            return;
        }
        
        NSDictionary *responseDict = (NSDictionary *)responseObject;
        NSInteger code = [responseDict[@"code"] integerValue];
        NSString *msg = [responseDict[@"msg"] isKindOfClass:[NSString class]] ? responseDict[@"msg"] : @"";

        if (code != 200) {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALPostManager"
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey: msg}];
                completion(nil, NO, error);
            }
            return;
        }
        
        NSDictionary *data = nil;
        if ([responseDict[@"data"] isKindOfClass:[NSDictionary class]]) {
            data = responseDict[@"data"];
        }

        NSInteger totalCount = [data[@"total"] respondsToSelector:@selector(integerValue)] ? [data[@"total"] integerValue] : 0;
        NSInteger totalPages = totalCount > 0 ? MAX((totalCount + pageSize - 1) / pageSize, 1) : 1;
        if (randomizePage && requestedPage == 1 && totalPages > 1) {
            NSInteger excludedPage = MAX(self.lastDisplayedHomeFeedPage, 1);
            NSInteger randomPage = [self randomHomeFeedPageWithTotalPages:totalPages excludingPage:excludedPage];
            [self requestLatestPostsWithCachedPosts:cachedPosts
                                              page:randomPage
                                      randomizePage:NO
                                         completion:completion];
            return;
        }

        NSArray *list = nil;
        if ([data[@"list"] isKindOfClass:[NSArray class]]) {
            list = data[@"list"];
        }

        if (!list) {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALPostManager" code:-2 userInfo:@{NSLocalizedDescriptionKey : @"Missing data.list"}];
                completion(nil, NO, error);
            }
            return;
        }

        NSMutableArray<YALPostModel *> *posts = [NSMutableArray arrayWithCapacity:list.count];
        for (id item in list) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSDictionary *dic = (NSDictionary *)item;
            if (!YALPostManagerShouldShowPublicContent(dic)) {
                continue;
            }
            YALPostModel *model = [[YALPostModel alloc] initWithDictionary:dic];
            if (!model.isPublic) {
                continue;
            }
            [posts addObject:model];
        }

        [self resolveCollectCountsFromDetailForPosts:posts completion:^(NSArray<YALPostModel *> *resolvedPosts) {
            self.lastDisplayedHomeFeedPage = requestedPage;
            [[YALPostCacheStore sharedStore] replaceHomeFeedPosts:resolvedPosts completion:^(NSError * _Nullable cacheError) {
                (void)cacheError;
            }];

            if (completion) {
                completion(resolvedPosts, NO, nil);
            }
        }];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            if (cachedPosts.count > 0) {
                completion(cachedPosts, YES, error);
            } else {
                completion(nil, NO, error);
            }
        }
    }];
}

- (NSInteger)randomHomeFeedPageWithTotalPages:(NSInteger)totalPages excludingPage:(NSInteger)excludedPage {
    if (totalPages <= 1) {
        return 1;
    }

    NSMutableArray<NSNumber *> *candidates = [NSMutableArray array];
    for (NSInteger page = 1; page <= totalPages; page++) {
        if (page == excludedPage) {
            continue;
        }
        [candidates addObject:@(page)];
    }
    if (candidates.count == 0) {
        return 1;
    }

    u_int32_t index = arc4random_uniform((u_int32_t)candidates.count);
    return candidates[index].integerValue;
}

- (void)fetchAllPublicPostsForRefreshWithCompletion:(void(^)(NSArray<YALPostModel *> * _Nullable posts, NSError * _Nullable error))completion {
    YALNetworkManager *manager = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/list", YALAPIBaseURLString];
    NSInteger const pageSize = 30;
    NSInteger const maxPages = 20;
    __block NSInteger page = 1;
    __block NSInteger totalPages = 1;
    __block NSMutableArray<YALPostModel *> *aggregatedPosts = [NSMutableArray array];

    __weak typeof(self) weakSelf = self;
    __block void (^fetchNextPage)(void) = ^{
        NSDictionary *parameters = @{
            @"page": @(page),
            @"size": @(pageSize)
        };
        [manager GET:url parameters:parameters headers:nil progress:nil success:^(__unused NSURLSessionDataTask *task, id responseObject) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }

            if (![responseObject isKindOfClass:[NSDictionary class]]) {
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"YALPostManager"
                                                         code:-1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Invalid response object"}];
                    completion(nil, error);
                }
                return;
            }

            NSDictionary *responseDict = (NSDictionary *)responseObject;
            NSInteger code = [responseDict[@"code"] integerValue];
            NSString *msg = [responseDict[@"msg"] isKindOfClass:[NSString class]] ? responseDict[@"msg"] : @"";
            if (code != 200) {
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"YALPostManager"
                                                         code:code
                                                     userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"首页刷新失败"}];
                    completion(nil, error);
                }
                return;
            }

            NSDictionary *data = [responseDict[@"data"] isKindOfClass:[NSDictionary class]] ? responseDict[@"data"] : nil;
            NSArray *list = [data[@"list"] isKindOfClass:[NSArray class]] ? data[@"list"] : @[];
            NSInteger totalCount = [data[@"total"] respondsToSelector:@selector(integerValue)] ? [data[@"total"] integerValue] : list.count;
            totalPages = MAX((totalCount + pageSize - 1) / pageSize, 1);

            for (id item in list) {
                if (![item isKindOfClass:[NSDictionary class]]) {
                    continue;
                }
                NSDictionary *dic = (NSDictionary *)item;
                if (!YALPostManagerShouldShowPublicContent(dic)) {
                    continue;
                }
                YALPostModel *model = [[YALPostModel alloc] initWithDictionary:dic];
                if (!model.isPublic) {
                    continue;
                }
                [aggregatedPosts addObject:model];
            }

            BOOL reachedLastPage = (page >= totalPages || list.count < pageSize || page >= maxPages);
            if (reachedLastPage) {
                [strongSelf resolveCollectCountsFromDetailForPosts:[aggregatedPosts copy] completion:^(NSArray<YALPostModel *> *resolvedPosts) {
                    if (completion) {
                        completion(resolvedPosts, nil);
                    }
                }];
                return;
            }

            page += 1;
            fetchNextPage();
        } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
            if (completion) {
                completion(nil, error);
            }
        }];
    };

    fetchNextPage();
}

- (void)resolveCollectCountsFromDetailForPosts:(NSArray<YALPostModel *> *)posts
                                    completion:(void(^)(NSArray<YALPostModel *> *resolvedPosts))completion {
    if (posts.count == 0) {
        if (completion) {
            completion(posts ?: @[]);
        }
        return;
    }

    dispatch_group_t group = dispatch_group_create();

    for (YALPostModel *post in posts) {
        if (post.contentId.integerValue <= 0) {
            continue;
        }

        dispatch_group_enter(group);
        [[YALContentManager sharedManager] getContentDetailWithId:post.contentId completion:^(BOOL success, NSDictionary * _Nullable content, NSError * _Nullable error) {
            (void)error;
            if (success && [content isKindOfClass:[NSDictionary class]]) {
                NSInteger detailCollectCount = [self resolvedCollectCountFromContent:content fallback:post.collectCount];
                post.collectCount = MAX(detailCollectCount, 0);
                NSString *resolvedCity = [self resolvedCityFromContent:content fallback:post.city];
                post.city = resolvedCity ?: @"";
            }
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            completion(posts);
        }
    });
}

- (NSInteger)resolvedCollectCountFromContent:(NSDictionary *)content fallback:(NSInteger)fallback {
    NSArray<NSString *> *keys = @[@"collect_count", @"favorite_count", @"collected_count", @"collectCount", @"favoriteCount"];
    for (NSString *key in keys) {
        id value = content[key];
        if ([value respondsToSelector:@selector(integerValue)]) {
            return MAX([value integerValue], 0);
        }
    }

    NSArray<NSString *> *nestedKeys = @[@"data", @"content", @"item", @"post"];
    for (NSString *nestedKey in nestedKeys) {
        id nested = content[nestedKey];
        if ([nested isKindOfClass:[NSDictionary class]]) {
            NSInteger nestedValue = [self resolvedCollectCountFromContent:(NSDictionary *)nested fallback:NSNotFound];
            if (nestedValue != NSNotFound) {
                return MAX(nestedValue, 0);
            }
        }
    }

    return MAX(fallback, 0);
}

- (NSString *)resolvedCityFromContent:(NSDictionary *)content fallback:(NSString *)fallback {
    NSString *resolved = YALPostManagerFirstNonEmptyStringRecursively(content, @[@"city", @"location_name", @"locationName"]);
    if (resolved.length > 0) {
        return resolved;
    }
    NSString *trimmedFallback = [fallback stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmedFallback.length > 0 ? trimmedFallback : @"";
}

@end
