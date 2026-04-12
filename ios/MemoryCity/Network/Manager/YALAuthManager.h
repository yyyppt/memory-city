//
//  YALAuthManager.h
//  MemoryCity
//
//  Created by mac on 2026/3/26.
//

#import <Foundation/Foundation.h>
#import "../../Login/Model/YALAuthUserModel.h"

FOUNDATION_EXPORT NSString * _Nonnull const YALAuthManagerCurrentUserDidChangeNotification;

NS_ASSUME_NONNULL_BEGIN

@interface YALAuthManager : NSObject

+ (instancetype _Nonnull)sharedManager;

// 已在登录接口解析并落库双 token 后的用户信息；冷启动时会根据 access token 尝试从缓存恢复。
@property (nonatomic, strong, nullable) YALAuthUserModel *currentUser;

/// 当前 access token。统一从安全存储读取。
@property (nonatomic, copy, readonly, nullable) NSString *accessToken;

/// 当前 refresh token。统一从安全存储读取。
@property (nonatomic, copy, readonly, nullable) NSString *refreshToken;

/// access token 存在（与 `saveTokensFromLoginData:` 写入的 key 一致）即视为已登录会话。
- (BOOL)hasLoggedInSession;

/// 清除 access / refresh token、本地缓存的用户资料与 `currentUser`。
- (void)clearAuthSession;

/// 获取认证headers（包含token）
- (NSDictionary * _Nullable)getAuthHeadersWithToken;

/// 获取登录请求所需的认证headers
- (NSDictionary * _Nullable)authHeadersForLoginRequiredRequest;

/// 统一写入 access / refresh token；refresh 可为空。
- (void)storeAccessToken:(NSString * _Nullable)accessToken
            refreshToken:(NSString * _Nullable)refreshToken;

/// 自动刷新 access token。
- (void)refreshAccessTokenWithCompletion:(void (^ _Nonnull)(BOOL success))completion;

- (void)loginWithUsername:(NSString * _Nonnull)userName password:(NSString * _Nonnull)password completion:(void(^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion;
- (void)registerWithUsername:(NSString * _Nonnull)username password:(NSString * _Nonnull)password nickname:(NSString * _Nonnull)nickname completion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion;
- (void)registerWithUsername:(NSString * _Nonnull)username phone:(NSString * _Nonnull)phone password:(NSString * _Nonnull)password nickname:(NSString * _Nonnull)nickname completion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion;

/// 更新用户信息
- (void)updateUserWithNickname:(NSString * _Nonnull)nickname 
                           bio:(NSString * _Nullable)bio 
                    completion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion;

/// 更新用户信息（支持昵称和头像）
- (void)updateUserInfoWithNickname:(NSString * _Nonnull)nickname
                           avatar:(NSString * _Nonnull)avatar
                       completion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion;

/// 一次性更新用户资料（支持昵称/头像/bio；bio/avatar 可选）
- (void)updateUserInfoWithNickname:(NSString * _Nonnull)nickname
                              avatar:(NSString * _Nullable)avatar
                                 bio:(NSString * _Nullable)bio
                          completion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion;

/// 拉取当前登录用户信息（GET /user/info）
- (void)fetchUserInfoWithCompletion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion;

/// 拉取指定用户主页信息（GET /user/profile）
- (void)fetchUserProfileWithUserId:(NSNumber * _Nonnull)userId
                        completion:(void (^ _Nonnull)(NSDictionary * _Nullable profile, NSError * _Nullable error))completion;

/// 修改密码
- (void)updatePasswordWithOldPassword:(NSString * _Nonnull)oldPassword
                          newPassword:(NSString * _Nonnull)newPassword
                        repeatPassword:(NSString * _Nonnull)repeatPassword
                            completion:(void (^ _Nonnull)(BOOL success, NSString * _Nullable message, NSError * _Nullable error))completion;

/// 忘记密码：根据用户名和手机号发送验证码。
- (void)requestPasswordResetCodeForUsername:(NSString * _Nonnull)username
                                      phone:(NSString * _Nonnull)phone
                              completion:(void (^ _Nonnull)(BOOL success, NSString * _Nullable message, NSError * _Nullable error))completion;

/// 忘记密码：根据用户名、手机号和验证码修改密码。
- (void)resetPasswordForUsername:(NSString * _Nonnull)username
                           phone:(NSString * _Nonnull)phone
                verificationCode:(NSString * _Nonnull)code
                  newPassword:(NSString * _Nonnull)newPassword
                repeatPassword:(NSString * _Nonnull)repeatPassword
                    completion:(void (^ _Nonnull)(BOOL success, NSString * _Nullable message, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
