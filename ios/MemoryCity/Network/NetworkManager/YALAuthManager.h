//
//  YALAuthManager.h
//  MemoryCity
//
//  Created by mac on 2026/3/26.
//

#import <Foundation/Foundation.h>
#import "../../Login/Model/YALAuthUserModel.h"


@interface YALAuthManager : NSObject

+ (instancetype)sharedManager;

// 已在登录接口解析并落库双 token 后的用户信息；冷启动时会根据 access token 尝试从缓存恢复。
@property (nonatomic, strong, nullable) YALAuthUserModel *currentUser;

/// access token 存在（与 `saveTokensFromLoginData:` 写入的 key 一致）即视为已登录会话。
- (BOOL)hasLoggedInSession;

/// 清除 access / refresh token、本地缓存的用户资料与 `currentUser`。
- (void)clearAuthSession;

- (void)loginWithUsername:(NSString *)userName password:(NSString *)password completion:(void(^)(YALAuthUserModel *user, NSError *error))completion;
- (void)registerWithUsername:(NSString *)username password:(NSString *)password nickname:(NSString *)nickname completion:(void (^)(YALAuthUserModel *user, NSError *error))completion;

@end
