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
    NSString *url = @"http://8.137.158.7:9000/api/content/list";
    NSDictionary *parameters = @{@"limit": @10};
    [manager GET:url parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALPostManager" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Invalid response object"}];
                completion(nil, error);
            }
            return;
        }
        
        NSDictionary *data = nil;
        if ([responseObject[@"data"] isKindOfClass:[NSDictionary class]]) {
            data = responseObject[@"data"];
        }
        
        NSArray *list = nil;
        if ([data[@"list"] isKindOfClass:[NSArray class]]) {
            list = data[@"list"];
        }
        if (!list) {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALPostManager" code:-2 userInfo:@{NSLocalizedDescriptionKey : @"Missing data.list"}];
                completion(nil, error);
            }
            return;
        }
        
        NSMutableArray<YALPostModel *> *posts = [NSMutableArray arrayWithCapacity:list.count];
        for (id item in list) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSDictionary *dic = (NSDictionary *)item;
            YALPostModel *model = [[YALPostModel alloc] init];
            if ([dic[@"title"] isKindOfClass:[NSString class]]) {
                model.title = dic[@"title"];
            } else {
                model.title = @"";
            }
            if ([dic[@"content"] isKindOfClass:[NSString class]]) {
                model.desc = dic[@"content"];
            } else {
                model.desc = @"";
            }
            if ([UIImage systemImageNamed:@"photo"]) {
                model.image = [UIImage systemImageNamed:@"photo"];
            } else {
                model.image = [[UIImage alloc] init];
            }
            model.imageWidth = 0.0;
            model.imageHeight = 0.0;
            NSArray *images = nil;
            if ([dic[@"Images"] isKindOfClass:[NSArray class]]) {
                images = dic[@"Images"];
            }
            if (images.count > 0 && [images.firstObject isKindOfClass:[NSString class]]) {
                model.imageURLString = images.firstObject;
            } else {
                model.imageURLString = @"";
            }
            [posts addObject:model];
        }
        if (completion) {
            completion(posts, nil);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

@end
