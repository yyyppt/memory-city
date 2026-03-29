//
//  YALContentManager.m
//  MemoryCity
//
//  Created by mac on 2026/3/29.
//

#import "YALContentManager.h"
#import "YALNetworkManager.h"
#import "YALAuthManager.h"

static NSString * const kYALAPIBaseURL = @"http://8.137.158.7:9000/api";
//static NSString * const kYALAPIBaseURL = @"http://192.168.110.174:9000/api";
@implementation YALContentManager

+ (instancetype)sharedManager {
    static YALContentManager *contentManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        contentManager = [[YALContentManager alloc] init];
    });
    return contentManager;
}

- (void)publishContentWithTitle:(NSString *)title
                       content:(NSString *)content
                          city:(NSString *)city
                          year:(NSString *)year
                          mood:(NSString *)mood
                        images:(NSArray<NSString *> *)images
                  locationName:(nullable NSString *)locationName
                      latitude:(double)latitude
                     longitude:(double)longitude
                      isPublic:(BOOL)isPublic
                        userId:(nullable NSNumber *)userId
                     completion:(void (^)(BOOL success, NSString *message, NSNumber * _Nullable contentId, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/publish", kYALAPIBaseURL];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"title"] = title;
    parameters[@"content"] = content;
    parameters[@"city"] = city;
    parameters[@"year"] = year;
    parameters[@"mood"] = mood;
    // 处理图片上传
    if (images && [images isKindOfClass:[NSArray class]] && images.count > 0) {
        NSLog(@"📸 上传 %lu 张图片", (unsigned long)images.count);
        parameters[@"images"] = images;
        
        // 如果是Base64图片，记录大小
        if (images.count > 0 && [images.firstObject isKindOfClass:[NSString class]]) {
            NSString *firstImage = images.firstObject;
            if ([firstImage containsString:@"base64"] || firstImage.length > 100) {
                NSLog(@"⚠️ 检测到Base64图片，长度: %lu 字符", (unsigned long)firstImage.length);
                if (firstImage.length > 10000) {
                    NSLog(@"⚠️ 图片较大，建议使用OSS上传");
                }
            }
        }
    } else {
        parameters[@"images"] = @[];
        NSLog(@"📸 没有图片需要上传");
    }
    parameters[@"latitude"] = @(latitude);
    parameters[@"longitude"] = @(longitude);
    parameters[@"is_public"] = @(isPublic);
    
    if (locationName) {
        parameters[@"location_name"] = locationName;
    }
    
    NSNumber *finalUserId = nil;

    if (userId) {
        if ([userId isKindOfClass:[NSNumber class]]) {
            finalUserId = userId;
        } else if ([userId isKindOfClass:[NSString class]]) {
            NSInteger uid = [(NSString *)userId integerValue];
            if (uid > 0) {
                finalUserId = @(uid);
            }
        }
    }

    // 如果解析失败，尝试从当前登录用户获取userId
    if (!finalUserId) {
        YALAuthUserModel *currentUser = [[YALAuthManager sharedManager] currentUser];
        if (currentUser && currentUser.userId > 0) {
            finalUserId = @(currentUser.userId);
            NSLog(@"⚠️ userId异常，使用当前登录用户ID: %ld", (long)currentUser.userId);
        } else {
            // 如果没有登录用户，使用默认值1
            NSLog(@"⚠️ userId异常，使用默认值1");
            finalUserId = @(1);
        }
    }

    // 确保user_id是NSNumber类型且值大于0
    if (![finalUserId isKindOfClass:[NSNumber class]] || [finalUserId integerValue] <= 0) {
        NSLog(@"❌ user_id格式错误，使用默认值1");
        finalUserId = @(1);
    }
    
    parameters[@"user_id"] = finalUserId;
    NSLog(@"🔥 最终 user_id = %@, 类型 = %@, 值 = %ld", finalUserId, [finalUserId class], (long)[finalUserId integerValue]);
    NSLog(@"📦 最终发送参数: %@", parameters);
    

    
    // 获取认证headers
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];
    
    NSLog(@"📡 网络请求详情：");
    NSLog(@"🔗 URL: %@", url);
    NSLog(@"📦 参数: %@", parameters);
    NSLog(@"🔑 Headers: %@", headers);
    
    [network POST:url
        parameters:parameters
           headers:headers
           progress:nil
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSLog(@"✅ 网络请求成功，收到响应：");
        NSLog(@"📥 响应数据: %@", responseObject);
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
            NSDictionary *data = [response[@"data"] isKindOfClass:[NSDictionary class]] ? response[@"data"] : nil;
            
            NSLog(@"📊 响应状态: 代码=%ld, 消息=%@", (long)code, msg);
            NSLog(@"📁 响应数据: %@", data);
            
            if (code == 200) {
                NSNumber *contentId = data[@"content_id"];
                NSLog(@"🎉 发布成功，内容ID: %@", contentId);
                if (completion) {
                    completion(YES, msg, contentId, nil);
                }
            } else {
                NSLog(@"⚠️ 服务器返回错误: 代码=%ld, 消息=%@", (long)code, msg);
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                        code:code
                                                    userInfo:@{NSLocalizedDescriptionKey: msg}];
                    completion(NO, msg, nil, error);
                }
            }
        } else {
            NSLog(@"❌ 无效的响应格式: %@", responseObject);
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                    code:-1
                                                userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}];
                completion(NO, @"无效的响应", nil, error);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 网络请求失败: %@", error);
        if (completion) {
            completion(NO, @"网络请求失败", nil, error);
        }
    }];
}

- (void)getContentDetailWithId:(NSNumber *)contentId
                    completion:(void (^)(BOOL success, NSDictionary * _Nullable content, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/detail", kYALAPIBaseURL];
    
    NSDictionary *parameters = @{@"content_id": contentId};
    
    // 获取认证headers
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];
    
    [network GET:url
     parameters:parameters
        headers:headers
       progress:nil
        success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
            NSDictionary *data = [response[@"data"] isKindOfClass:[NSDictionary class]] ? response[@"data"] : nil;
            
            if (code == 200) {
                if (completion) {
                    completion(YES, data, nil);
                }
            } else {
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                        code:code
                                                    userInfo:@{NSLocalizedDescriptionKey: msg}];
                    completion(NO, nil, error);
                }
            }
        } else {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                    code:-1
                                                userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}];
                completion(NO, nil, error);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, nil, error);
        }
    }];
}

#pragma mark - 获取我的内容列表

- (void)getMyContentListWithPage:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                      completion:(void (^)(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/my", kYALAPIBaseURL];
    
    // 构建请求参数
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"page"] = @(page);
    parameters[@"pageSize"] = @(pageSize);
    
    // 获取认证headers（需要token）
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];
    
    NSLog(@"📡 获取我的内容列表请求详情：");
    NSLog(@"🔗 URL: %@", url);
    NSLog(@"📦 参数: %@", parameters);
    NSLog(@"🔑 Headers: %@", headers);
    
    [network GET:url
      parameters:parameters
         headers:headers
        progress:nil
         success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSLog(@"✅ 获取我的内容列表成功，收到响应：");
        NSLog(@"📥 响应数据: %@", responseObject);
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
            NSDictionary *data = [response[@"data"] isKindOfClass:[NSDictionary class]] ? response[@"data"] : nil;
            
            NSLog(@"📊 响应状态: 代码=%ld, 消息=%@", (long)code, msg);
            
            if (code == 200) {
                // 解析数据列表
                NSArray *listData = [data[@"list"] isKindOfClass:[NSArray class]] ? data[@"list"] : @[];
                NSMutableArray *contentList = [NSMutableArray array];
                
                for (NSDictionary *itemDict in listData) {
                    if ([itemDict isKindOfClass:[NSDictionary class]]) {
                        // 这里需要导入YALMyContentModel，但为了不破坏现有结构，我们先返回字典数组
                        // 在实际使用中，ViewController会将其转换为模型
                        [contentList addObject:itemDict];
                    }
                }
                
                NSLog(@"📋 解析成功，共 %lu 条内容", (unsigned long)contentList.count);
                
                if (completion) {
                    completion(YES, [contentList copy], msg, nil);
                }
            } else {
                NSLog(@"⚠️ 服务器返回错误: 代码=%ld, 消息=%@", (long)code, msg);
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                        code:code
                                                    userInfo:@{NSLocalizedDescriptionKey: msg}];
                    completion(NO, nil, msg, error);
                }
            }
        } else {
            NSLog(@"❌ 无效的响应格式: %@", responseObject);
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                    code:-1
                                                userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
                completion(NO, nil, @"无效的响应格式", error);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 获取我的内容列表失败: %@", error);
        if (completion) {
            completion(NO, nil, @"网络请求失败", error);
        }
    }];
}

@end
