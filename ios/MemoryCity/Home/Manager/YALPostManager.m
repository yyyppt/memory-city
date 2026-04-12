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
            [lower isEqualToString:@"private"] ||
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

    NSArray<NSString *> *publicKeys = @[@"is_public", @"isPublic", @"visible", @"visibility", @"public_status"];
    for (NSString *key in publicKeys) {
        id value = dict[key];
        if (!value || value == [NSNull null]) {
            continue;
        }
        return YALPostManagerBoolValue(value, NO);
    }

    return NO;
}

@implementation YALPostManager
                     
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
        NSArray<YALPostModel *> *cachedPosts = posts ?: @[];
        if (cachedPosts.count > 0) {
            NSLog(@"💾 首页命中 Core Data 缓存：%lu 条", (unsigned long)cachedPosts.count);
        }

        [self requestLatestPostsWithCachedPosts:cachedPosts completion:completion];
    }];
}

- (void)requestLatestPostsWithCachedPosts:(NSArray<YALPostModel *> *)cachedPosts
                               completion:(void(^)(NSArray<YALPostModel *> * _Nullable posts, BOOL fromCache, NSError * _Nullable error))completion {
    YALNetworkManager *manager = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/list", YALAPIBaseURLString];

    NSDictionary *parameters = @{@"limit": @10};

    NSLog(@"📡 首页获取内容列表请求：%@", url);
    NSLog(@"📦 请求参数：%@", parameters);

    [manager GET:url parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"✅ 首页获取内容列表成功，收到响应：");

        // 打印完整的响应数据，方便调试
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *responseDict = (NSDictionary *)responseObject;
            NSLog(@"📥 完整响应数据：%@", responseDict);

            // 打印data部分
        if ([responseDict[@"data"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *data = responseDict[@"data"];
                NSLog(@"📁 数据部分：%@", data);

                // 打印list中的第一条数据，查看字段结构
        if ([data[@"list"] isKindOfClass:[NSArray class]]) {
                    NSArray *list = data[@"list"];
                    if (list.count > 0) {
                        NSLog(@"🔍 第一条数据字段：%@", list[0]);
                        // 特别检查图片字段
                        if ([list[0] isKindOfClass:[NSDictionary class]]) {
                            NSDictionary *firstItem = list[0];
                            NSLog(@"🖼️ 图片相关字段：");
                            NSLog(@"   images: %@", firstItem[@"images"]);
                            NSLog(@"   Images: %@", firstItem[@"Images"]);
                            NSLog(@"   image_urls: %@", firstItem[@"image_urls"]);
        }
                    }
                }
            }
        }

        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            NSLog(@"❌ 无效的响应格式");
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
            NSLog(@"⚠️ 服务器返回错误: 代码=%ld, 消息=%@", (long)code, msg);
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

        NSArray *list = nil;
        if ([data[@"list"] isKindOfClass:[NSArray class]]) {
            list = data[@"list"];
        }

        if (!list) {
            NSLog(@"⚠️ 缺少数据列表");
        if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALPostManager" code:-2 userInfo:@{NSLocalizedDescriptionKey : @"Missing data.list"}];
                completion(nil, NO, error);
            }
            return;
        }
        
        NSLog(@"📋 解析到 %lu 条内容", (unsigned long)list.count);

        NSMutableArray<YALPostModel *> *posts = [NSMutableArray arrayWithCapacity:list.count];
        for (id item in list) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSDictionary *dic = (NSDictionary *)item;
            if (!YALPostManagerShouldShowPublicContent(dic)) {
                NSLog(@"🔒 首页原始数据过滤掉非公开内容ID: %@", dic[@"content_id"]);
                continue;
            }
            YALPostModel *model = [[YALPostModel alloc] initWithDictionary:dic];
            if (!model.isPublic) {
                NSLog(@"🔒 跳过私密内容ID: %@", model.contentId);
                continue;
            }
            [posts addObject:model];

            // 打印每条数据的图片信息
            NSLog(@"📸 内容ID %@ 的图片URL: %@", model.contentId, model.imageURLString);
        }

        [self resolveCollectCountsFromDetailForPosts:posts completion:^(NSArray<YALPostModel *> *resolvedPosts) {
            [[YALPostCacheStore sharedStore] replaceHomeFeedPosts:resolvedPosts completion:^(NSError * _Nullable cacheError) {
                if (cacheError) {
                    NSLog(@"⚠️ 首页缓存更新失败: %@", cacheError);
                }
            }];

            if (completion) {
                completion(resolvedPosts, NO, nil);
            }
        }];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 首页获取内容列表失败: %@", error);
        if (completion) {
            if (cachedPosts.count > 0) {
                completion(cachedPosts, YES, error);
            } else {
                completion(nil, NO, error);
            }
        }
    }];
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
