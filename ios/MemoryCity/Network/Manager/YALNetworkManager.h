//
//  YALNetworkManager.h
//  MemoryCity
//
//  Created by mac on 2026/3/23.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface YALNetworkManager : NSObject

@property (nonatomic, strong) AFHTTPSessionManager * _Nullable sessionManager;

+ (instancetype _Nullable )shareManager;
- (void)GET:(NSString *_Nonnull)URLString parameters:(nullable id)parameters headers:(nullable NSDictionary<NSString *,NSString *> *)headers progress:(nullable void (^)(NSProgress * _Nonnull))downloadProgress success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure;

/// POST(JSON) 请求封装
- (void)POST:(NSString *_Nonnull)URLString
    parameters:(nullable id)parameters
       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
       progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
        success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
        failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure;

/// PUT(JSON) 请求封装
- (void)PUT:(NSString *_Nonnull)URLString
 parameters:(nullable id)parameters
    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
    success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
    failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure;

/// DELETE(JSON) 请求封装
- (void)DELETE:(NSString *_Nonnull)URLString
    parameters:(nullable id)parameters
       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
       success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
       failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure;


@end

