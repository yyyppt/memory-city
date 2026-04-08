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
        self.sessionManager.requestSerializer.timeoutInterval = 30.0;
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
        success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
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

- (void)PUT:(NSString *_Nonnull)URLString
 parameters:(nullable id)parameters
    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
    success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
    failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    // 使用 AFJSONRequestSerializer / AFJSONResponseSerializer
    [self.sessionManager PUT:URLString parameters:parameters headers:headers success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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

- (void)DELETE:(NSString *_Nonnull)URLString
    parameters:(nullable id)parameters
       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
       success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
       failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    BOOL hasJSONBody = [parameters isKindOfClass:[NSDictionary class]] && [(NSDictionary *)parameters count] > 0;
    if (!hasJSONBody) {
        [self.sessionManager DELETE:URLString parameters:nil headers:headers success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
        return;
    }

    NSError *requestError = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    request.HTTPMethod = @"DELETE";
    request.timeoutInterval = self.sessionManager.requestSerializer.timeoutInterval;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, __unused BOOL * _Nonnull stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&requestError];
    if (jsonData) {
        request.HTTPBody = jsonData;
    }
    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) {
                failure(nil, requestError);
            }
        });
        return;
    }

    __block NSURLSessionDataTask *task = nil;
    task = [self.sessionManager dataTaskWithRequest:request
                                     uploadProgress:nil
                                   downloadProgress:nil
                                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) {
                    failure((NSURLSessionDataTask *)nil, error);
                }
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                success((NSURLSessionDataTask *)task, responseObject);
            }
        });
    }];
    [task resume];
}

@end
