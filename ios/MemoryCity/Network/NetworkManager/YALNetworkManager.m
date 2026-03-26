//
//  YALNetworkManager.m
//  MemoryCity
//
//  Created by mac on 2026/3/23.
//

#import "YALNetworkManager.h"

@implementation YALNetworkManager

+ (instancetype _Nullable )shareManager {
    static YALNetworkManager *networkManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkManager = [[YALNetworkManager alloc] init];
    });
    return networkManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.sessionManager = [AFHTTPSessionManager manager];
        self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        self.sessionManager.requestSerializer.timeoutInterval = 15.0;
        self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        //self.sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", @"text/html", nil];
        // 开启Cookie支持
        self.sessionManager.requestSerializer.HTTPShouldHandleCookies = YES;
        [NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    }
    return self;
}

- (void)GET:(NSString *_Nonnull)URLString parameters:(nullable id)parameters headers:(nullable NSDictionary<NSString *,NSString *> *)headers progress:(nullable void (^)(NSProgress * _Nonnull))downloadProgress success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    [self.sessionManager GET:URLString parameters:parameters headers:headers progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                success(task, responseObject);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) {
                failure(task, error);
            }
        });
    }];
}

- (void)POST:(NSString *_Nonnull)URLString
    parameters:(nullable id)parameters
       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
       progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
        success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject))success
        failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    // 注意：当前 sessionManager 统一使用 AFJSONRequestSerializer / AFJSONResponseSerializer
    [self.sessionManager POST:URLString parameters:parameters headers:headers progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                success(task, responseObject);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) {
                failure(task, error);
            }
        });
    }];
}

@end
