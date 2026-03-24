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


@end
