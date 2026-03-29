//
//  YALAuthManager.h
//  MemoryCity
//
//  Created by mac on 2026/3/26.
//

#import <Foundation/Foundation.h>
#import "../../Login/Model/YALAuthUserModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YALAuthManager : NSObject

+ (instancetype _Nonnull)sharedManager;

/// 已在登录接口解析并落库双 token 后的用户信息；冷启动时会根据 access token 尝试从缓存恢复。
@property (nonatomic, strong, nullable) YALAuthUserModel *currentUser;

/// access token 存在（与 `saveTokensFromLoginData:` 写入的 key 一致）即视为已登录会话。
- (BOOL)hasLoggedInSession;

/// 清除 access / refresh token、本地缓存的用户资料与 `currentUser`。
- (void)clearAuthSession;

/// 获取认证headers（包含token）
- (NSDictionary * _Nullable)getAuthHeadersWithToken;

/// 获取登录请求所需的认证headers
- (NSDictionary * _Nullable)authHeadersForLoginRequiredRequest;

- (void)loginWithUsername:(NSString * _Nonnull)userName password:(NSString * _Nonnull)password completion:(void(^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion;
- (void)registerWithUsername:(NSString * _Nonnull)username password:(NSString * _Nonnull)password nickname:(NSString * _Nonnull)nickname completion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
