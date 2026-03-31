//
//  YALPostManager.m
//  MemoryCity
//
//  Created by mac on 2026/3/23.
//

#import "YALPostManager.h"

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
    YALNetworkManager *manager = [YALNetworkManager shareManager];
    //static NSString * const kYALAPIBaseURL = @"http://8.137.158.7:9000/api";@"http://8.137.158.7:9000/api/content/list";http://192.168.1.65:9000/api

    NSString *url = @"http://8.137.158.7:9000/api/content/list";
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
                completion(nil, error);
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
                completion(nil, error);
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
                completion(nil, error);
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
            YALPostModel *model = [[YALPostModel alloc] initWithDictionary:dic];
            [posts addObject:model];

            // 打印每条数据的图片信息
            NSLog(@"📸 内容ID %@ 的图片URL: %@", model.contentId, model.imageURLString);
        }

        if (completion) {
            completion(posts, nil);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 首页获取内容列表失败: %@", error);
        if (completion) {
            completion(nil, error);
        }
    }];
}

@end

