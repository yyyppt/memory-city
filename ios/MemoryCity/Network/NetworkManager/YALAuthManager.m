
//@end
//  MemoryCity
//
//  Created by mac on 2026/3/26.
//

#import "YALAuthManager.h"

#import <AFNetworking/AFNetworking.h>

#import "YALNetworkManager.h"
#import "../../Login/Model/YALAuthUserModel.h"

static NSString * const accessTokenKey = @"YALAccessToken";
static NSString * const refreshTokenKey = @"YALRefreshToken";

static NSString * const userProfileUserIdKey = @"YALAuthUserProfileUserId";
static NSString * const userProfileUserIdStringKey = @"YALAuthUserProfileUserIdString";
static NSString * const userProfileNicknameKey = @"YALAuthUserProfileNickname";
static NSString * const userProfileAvatarKey = @"YALAuthUserProfileAvatar";
static NSString * const userProfileBioKey = @"YALAuthUserProfileBio";

static NSString * const kYALAPIBaseURL = @"http://8.137.158.7:9000/api";
//static NSString * const kYALAPIBaseURL = @"http://192.168.1.65:9000/api";

NSString * const YALAuthManagerCurrentUserDidChangeNotification = @"YALAuthManagerCurrentUserDidChangeNotification";

static id YALJSONNonNull(id obj) {
    if (obj == nil || obj == (id)[NSNull null]) {
        return nil;
    }
    return obj;
}

static id YALJSONObjectForKeys(NSDictionary *dict, NSArray<NSString *> *keys) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = YALJSONNonNull(dict[key]);
        if (value) {
            return value;
        }
    }
    return nil;
}

@implementation YALAuthManager

+ (instancetype)sharedManager {
    static YALAuthManager *authManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        authManager = [[YALAuthManager alloc] init];
    });
    return authManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 开发模式下：每次启动应用都清除之前的登录状态
        // 这样在重新运行项目时不会保持登录状态
        #if DEBUG
        [self clearAuthSession];
        #endif
        
        // 然后尝试加载缓存用户（在生产环境中保持正常）
        [self loadCachedUserIfHasAccessToken];
    }
    return self;
}

- (BOOL)hasLoggedInSession {
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:accessTokenKey];
    return [accessToken isKindOfClass:[NSString class]] && accessToken.length > 0;
}

- (void)clearPersistedUserProfileOnly {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:userProfileUserIdKey];
    [defaults removeObjectForKey:userProfileUserIdStringKey];
    [defaults removeObjectForKey:userProfileNicknameKey];
    [defaults removeObjectForKey:userProfileAvatarKey];
    // 注意：这里不清理 bio。登录接口可能不返回 bio，清掉会导致“重新登录后简介丢失”。
    // bio 会在后续 setCurrentUser 时根据新返回字段/缓存自行更新/兜底。
}

- (void)loadCachedUserIfHasAccessToken {
    if (![self hasLoggedInSession]) {
        _currentUser = nil;
        return;
    }
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:accessTokenKey];
    NSInteger uid = [[NSUserDefaults standardUserDefaults] integerForKey:userProfileUserIdKey];
    NSString *uidString = [[NSUserDefaults standardUserDefaults] objectForKey:userProfileUserIdStringKey];
    if (![uidString isKindOfClass:[NSString class]]) {
        uidString = nil;
    }
    NSString *nickname = [[NSUserDefaults standardUserDefaults] objectForKey:userProfileNicknameKey];
    NSString *avatar = [[NSUserDefaults standardUserDefaults] objectForKey:userProfileAvatarKey];
    NSString *bio = [[NSUserDefaults standardUserDefaults] objectForKey:userProfileBioKey];
    if (![nickname isKindOfClass:[NSString class]]) {
        nickname = nil;
    }
    if (![avatar isKindOfClass:[NSString class]]) {
        avatar = nil;
    }
    if (![bio isKindOfClass:[NSString class]]) {
        bio = nil;
    }
    YALAuthUserModel *user = [[YALAuthUserModel alloc] init];
    user.userId = uid;
    user.username = uidString.length > 0 ? uidString : (uid > 0 ? [NSString stringWithFormat:@"%ld", (long)uid] : nil);
    user.nickname = nickname;
    user.avatar = avatar;
    user.bio = bio;
    user.token = [accessToken isKindOfClass:[NSString class]] ? accessToken : nil;
    _currentUser = user;
}

- (void)setCurrentUser:(YALAuthUserModel *)currentUser {
    _currentUser = currentUser;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (!currentUser) {
        [self clearPersistedUserProfileOnly];
        [defaults synchronize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:YALAuthManagerCurrentUserDidChangeNotification object:self];
        });
        return;
    }

    // 如果登录/更新接口不返回 bio，但本地已经缓存过 bio，则补回到 currentUser，避免“重新登录后 bio 变空”
    id existingBioObj = [defaults objectForKey:userProfileBioKey];
    BOOL hasExistingBio = ([existingBioObj isKindOfClass:[NSString class]] && [existingBioObj length] > 0);
    if (currentUser.bio.length == 0 && hasExistingBio) {
        currentUser.bio = existingBioObj;
    }

    [defaults setInteger:currentUser.userId forKey:userProfileUserIdKey];
    if (currentUser.username.length > 0) {
        [defaults setObject:currentUser.username forKey:userProfileUserIdStringKey];
    } else if (currentUser.userId > 0) {
        [defaults setObject:[NSString stringWithFormat:@"%ld", (long)currentUser.userId] forKey:userProfileUserIdStringKey];
    } else {
        [defaults removeObjectForKey:userProfileUserIdStringKey];
    }
    if (currentUser.nickname.length > 0) {
        [defaults setObject:currentUser.nickname forKey:userProfileNicknameKey];
    } else {
        [defaults removeObjectForKey:userProfileNicknameKey];
    }
    if (currentUser.avatar.length > 0) {
        [defaults setObject:currentUser.avatar forKey:userProfileAvatarKey];
    } else {
        [defaults removeObjectForKey:userProfileAvatarKey];
    }
    if (currentUser.bio.length > 0) {
        [defaults setObject:currentUser.bio forKey:userProfileBioKey];
    } else {
        // 登录/更新接口可能不会返回 bio，此时不要把缓存清空，避免“改完 bio 一刷新就没了”
        id existingBioObj = [defaults objectForKey:userProfileBioKey];
        BOOL hasExistingBio = ([existingBioObj isKindOfClass:[NSString class]] && [existingBioObj length] > 0);
        if (!hasExistingBio) {
            [defaults removeObjectForKey:userProfileBioKey];
        }
    }
    [defaults synchronize];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:YALAuthManagerCurrentUserDidChangeNotification object:self];
    });
}

- (void)applyUserIdentifierFromData:(NSDictionary *)data toUser:(YALAuthUserModel *)user {
    if (!user || ![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    // 先尝试获取 username
    id usernameObj = YALJSONObjectForKeys(data, @[ @"username", @"user_name", @"account", @"name" ]);
    NSDictionary *nestedUser = [data[@"user"] isKindOfClass:[NSDictionary class]] ? data[@"user"] : nil;
    if (!usernameObj && nestedUser) {
        usernameObj = YALJSONObjectForKeys(nestedUser, @[ @"username", @"user_name", @"account", @"name" ]);
    }
    if ([usernameObj isKindOfClass:[NSString class]]) {
        NSString *s = [((NSString *)usernameObj) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length > 0) {
            user.username = [s copy];
        }
    }
    
    // 再获取 userId
    id raw = YALJSONObjectForKeys(data, @[ @"user_id", @"userId", @"id" ]);
    if (!raw && nestedUser) {
        raw = YALJSONObjectForKeys(nestedUser, @[ @"user_id", @"userId", @"id" ]);
    }
    if (!raw) {
        return;
    }
    if ([raw isKindOfClass:[NSString class]]) {
        NSString *s = [((NSString *)raw) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) {
            return;
        }
        user.userId = [s integerValue];
    } else if ([raw isKindOfClass:[NSNumber class]]) {
        NSNumber *num = (NSNumber *)raw;
        user.userId = num.integerValue;
    }
}

- (void)clearAuthSession {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:accessTokenKey];
    [defaults removeObjectForKey:refreshTokenKey];
    [self clearPersistedUserProfileOnly];
    [defaults synchronize];
    _currentUser = nil;
}


- (NSDictionary *)getAuthHeadersWithToken {
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:accessTokenKey];
    NSString *refreshToken = [[NSUserDefaults standardUserDefaults] objectForKey:refreshTokenKey];
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    if ([accessToken isKindOfClass:[NSString class]] && accessToken.length > 0) {
        headers[@"Authorization"] = [NSString stringWithFormat:@"Bearer %@", accessToken];
    }
    if ([refreshToken isKindOfClass:[NSString class]] && refreshToken.length > 0) {
        headers[@"Refresh-Authorization"] = [NSString stringWithFormat:@"Bearer %@", refreshToken];
    }

    if (headers.count > 0) {
        return [headers copy];
    } else {
        return nil;
    }
}

- (NSDictionary *)authHeadersForLoginRequiredRequest {
    return [self getAuthHeadersWithToken];
}

- (void)refreshAccessTokenWithCompletion:(void (^)(BOOL success))completion {
    NSString *refreshToken = [[NSUserDefaults standardUserDefaults] objectForKey:refreshTokenKey];
    if (refreshToken.length == 0) {
        if (completion) completion(NO);
        return;
    }

    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/user/refresh", kYALAPIBaseURL];

    NSDictionary *headers = @{
        @"Refresh-Authorization": [NSString stringWithFormat:@"Bearer %@", refreshToken]
    };

    [network POST:url
        parameters:nil
           headers:headers
           progress:nil
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {

        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = (NSDictionary *)responseObject;
            NSDictionary *data = dic[@"data"];
            NSString *newToken = data[@"token"];

            if ([newToken isKindOfClass:[NSString class]] && newToken.length > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:newToken forKey:accessTokenKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                if (completion) completion(YES);
                return;
            }
        }

        if (completion) completion(NO);

    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) completion(NO);
    }];
}

- (void)saveTokensFromLoginData:(NSDictionary *)data {
    id tokenObj = data[@"token"];
    NSString *token = [tokenObj isKindOfClass:[NSString class]] ? tokenObj : nil;

    id refreshTokenObj = data[@"refresh_token"];
    if (!refreshTokenObj) {
        refreshTokenObj = data[@"refreshToken"];
    }
    // 兼容返回字段为 refreshtoken 的情况
    if (!refreshTokenObj) {
        refreshTokenObj = data[@"refreshtoken"];
    }
    NSString *refreshToken = [refreshTokenObj isKindOfClass:[NSString class]] ? refreshTokenObj : nil;

    // 兼容：如果后端只返回一个 token，就把它同时写入两个 key，保证“双 token”流程可跑通
    if (!refreshToken || refreshToken.length == 0) {
        refreshToken = token;
    }

    if (token && token.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:accessTokenKey];
    }
    if (refreshToken && refreshToken.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:refreshToken forKey:refreshTokenKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)handleAuthResponse:(id)responseObject
                 successData:(YALAuthUserModel * _Nonnull * _Nullable)outUser
                       error:(NSError * _Nullable * _Nullable)outError
                    isLogin:(BOOL)isLogin {
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"YALAuthManager"
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: @"Invalid response object"}];
        }
        return NO;
    }

    NSDictionary *dic = (NSDictionary *)responseObject;
    NSInteger code = [dic[@"code"] respondsToSelector:@selector(integerValue)] ? [dic[@"code"] integerValue] : -1;
    NSString *msg = [dic[@"msg"] isKindOfClass:[NSString class]] ? dic[@"msg"] : @"";
    NSDictionary *data = [dic[@"data"] isKindOfClass:[NSDictionary class]] ? dic[@"data"] : nil;

    if (code != 200) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"YALAuthManager"
                                            code:code
                                        userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"请求失败"}];
        }
        return NO;
    }

    if (!data) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"YALAuthManager"
                                            code:-2
                                        userInfo:@{NSLocalizedDescriptionKey: @"Missing response data"}];
        }
        return NO;
    }

    YALAuthUserModel *user = [[YALAuthUserModel alloc] init];
  id userIdObj = data[@"user_id"] ?: data[@"id"];

  if ([userIdObj respondsToSelector:@selector(integerValue)]) {
      user.userId = [userIdObj integerValue];
      NSLog(@"✅ 成功解析用户 ID: %ld", (long)user.userId);
  } else {
      NSLog(@"⚠️ 无法在数据源中找到有效的用户 ID");
  }
  NSDictionary *nestedUser = [data[@"user"] isKindOfClass:[NSDictionary class]] ? data[@"user"] : nil;
//  if (nestedUser) {
//       [self applyUserFieldsFromDictionary:nestedUser toUser:user];
//  }

    // username 可能在 data 或 nested user 中
    id usernameObj = YALJSONObjectForKeys(data, @[ @"username", @"user_name", @"userName", @"account", @"name" ]);
    if (!usernameObj && nestedUser) {
        usernameObj = YALJSONObjectForKeys(nestedUser, @[ @"username", @"user_name", @"userName", @"account", @"name" ]);
    }
    if ([usernameObj isKindOfClass:[NSString class]]) {
        NSString *s = [((NSString *)usernameObj) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length > 0) {
            user.username = [s copy];
        }
    } else if ([usernameObj isKindOfClass:[NSNumber class]]) {
        user.username = [(NSNumber *)usernameObj stringValue];
    }

    id nicknameObj = YALJSONObjectForKeys(data, @[ @"nickname" ]);
    if (!nicknameObj && nestedUser) {
        nicknameObj = YALJSONObjectForKeys(nestedUser, @[ @"nickname" ]);
    }
    user.nickname = [nicknameObj isKindOfClass:[NSString class]] ? nicknameObj : nil;

    id avatarObj = YALJSONObjectForKeys(data, @[ @"avatar" ]);
    if (!avatarObj && nestedUser) {
        avatarObj = YALJSONObjectForKeys(nestedUser, @[ @"avatar" ]);
    }
    user.avatar = [avatarObj isKindOfClass:[NSString class]] ? avatarObj : nil;

    // bio 可能在 data 或 nested user 中
    id bioObj = YALJSONObjectForKeys(data, @[ @"bio" ]);
    if (!bioObj && nestedUser) {
        bioObj = YALJSONObjectForKeys(nestedUser, @[ @"bio" ]);
    }
    user.bio = [bioObj isKindOfClass:[NSString class]] ? bioObj : nil;

    // 只有登录时才设置token和保存token
    if (isLogin) {
        id tokenObj = data[@"token"];
        user.token = [tokenObj isKindOfClass:[NSString class]] ? tokenObj : nil;
        [self saveTokensFromLoginData:data];
    }

    if (outUser) {
        *outUser = user;
    }

    // ✅ 关键修复：登录成功后必须保存 currentUser（否则 userId 为空/脏数据）
    if (isLogin) {
        self.currentUser = user;
        NSLog(@"✅ 登录成功，保存 userId = %ld", (long)user.userId);
    }

    return YES;
}

/// 登录接口（使用 completion 回调）
/// user != nil 表示成功
/// error != nil 表示失败
- (void)loginWithUsername:(NSString *)username
                  password:(NSString *)password
                completion:(void (^)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion {
    if (username.length == 0 || password.length == 0) {
        NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                         code:-3
                                     userInfo:@{NSLocalizedDescriptionKey: @"用户名或密码不能为空"}];
        if (completion) {
            completion(nil, e);
        }
        return;
    }

    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/user/login", kYALAPIBaseURL];
    NSString *u = @"";
    if (username) {
        u = username;
    }
    NSString *p = @"";
    if (password) {
        p = password;
    }
    NSDictionary *parameters = @{@"username": u,
                                 @"password": p};

    // 登录接口通常不需要 Authorization，但你要求“先写上双 token”，这里仍会带上已存在的 tokens（若无则不带）。
    NSDictionary *headers = nil;

    [network POST:url
        parameters:parameters
           headers:headers
           progress:nil
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        YALAuthUserModel *user = nil;
        NSError *error = nil;
        BOOL ok = [self handleAuthResponse:responseObject successData:&user error:&error isLogin:YES];
        if (ok) {
            self.currentUser = user;

            // 异步再拉一次 /user/info，补齐 bio/username 等字段（不阻塞登录结果回调）
            [self fetchUserInfoWithCompletion:^(__unused YALAuthUserModel * _Nullable fullUser, __unused NSError * _Nullable fullError) {
                // 这里不需要再调 completion，只更新 currentUser 即可
            }];
        }

        if (completion) {
            if (ok) {
                completion(user, nil);
            } else {
                completion(nil, error);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)fetchUserInfoWithCompletion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion {
    NSDictionary *headers = [self getAuthHeadersWithToken];
    if (![headers isKindOfClass:[NSDictionary class]] || headers.count == 0) {
        if (completion) {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:-40
                                         userInfo:@{NSLocalizedDescriptionKey: @"未登录或token缺失"}];
            completion(nil, e);
        }
        return;
    }

    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/user/info", kYALAPIBaseURL];

    NSLog(@"📡 拉取用户信息请求(GET): %@", url);

    [network GET:url
       parameters:nil
          headers:headers
         progress:nil
          success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSLog(@"✅ 拉取用户信息响应: %@", responseObject);
        YALAuthUserModel *user = nil;
        NSError *error = nil;
        BOOL ok = [self handleAuthResponse:responseObject successData:&user error:&error isLogin:NO];
        if (ok && user) {
            // 注意：handleAuthResponse(isLogin:NO) 不会保存 token，这里只更新资料
            self.currentUser = user;
            if (completion) {
                completion(user, nil);
            }
        } else {
            if (completion) {
                completion(nil, error ?: [NSError errorWithDomain:@"YALAuthManager"
                                                             code:-41
                                                         userInfo:@{NSLocalizedDescriptionKey: @"获取用户信息失败"}]);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 拉取用户信息失败(网络层): %@", error);
        if (completion) {
            completion(nil, error);
        }
    }];
}

/// 注册接口（使用 completion 回调）
/// user != nil 表示成功
/// error != nil 表示失败
- (void)registerWithUsername:(NSString *)username
                    password:(NSString *)password
                     nickname:(NSString *)nickname
                   completion:(void (^)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion {
    if (username.length == 0 || password.length == 0 || nickname.length == 0) {
        NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                         code:-4
                                     userInfo:@{NSLocalizedDescriptionKey: @"参数不能为空"}];
        if (completion) {
            completion(nil, e);
        }
        return;
    }

    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/user/register", kYALAPIBaseURL];
    NSString *u2 = @"";
    if (username) {
        u2 = username;
    }
    NSString *p2 = @"";
    if (password) {
        p2 = password;
    }
    NSString *n2 = @"";
    if (nickname) {
        n2 = nickname;
    }
    NSDictionary *parameters = @{@"username": u2,
                                 @"password": p2,
                                 @"nickname": n2};

    // 注册时不需要认证 headers
    NSDictionary *headers = nil;

    [network POST:url
        parameters:parameters
           headers:headers
           progress:nil
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        YALAuthUserModel *user = nil;
        NSError *error = nil;
        BOOL ok = [self handleAuthResponse:responseObject successData:&user error:&error isLogin:NO];
        if (completion) {
            if (ok) {
                completion(user, nil);
            } else {
                completion(nil, error);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)updateUserWithNickname:(NSString * _Nonnull)nickname
                           bio:(NSString * _Nullable)bio
                     completion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion {
    NSString *trimmedNickname = [nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimmedBio = nil;
    if (bio) {
        trimmedBio = [bio stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedBio.length == 0) {
            trimmedBio = nil;
        }
    }

    // 保存旧 userId/username：后端可能只返回 nickname/avatar，不返回 user_id
    YALAuthUserModel *previousUser = self.currentUser;

    if (trimmedNickname.length == 0) {
        if (completion) {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:-10
                                         userInfo:@{NSLocalizedDescriptionKey: @"昵称不能为空"}];
            completion(nil, e);
        }
        return;
    }

    NSDictionary *headers = [self getAuthHeadersWithToken];
    if (![headers isKindOfClass:[NSDictionary class]] || headers.count == 0) {
        if (completion) {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:-11
                                         userInfo:@{NSLocalizedDescriptionKey: @"未登录或token缺失"}];
            completion(nil, e);
        }
        return;
    }

    YALNetworkManager *network = [YALNetworkManager shareManager];
    // 文档：PUT /user/info，参数 nickname / avatar，可扩展 bio
    NSString *url = [NSString stringWithFormat:@"%@/user/info", kYALAPIBaseURL];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"nickname"] = trimmedNickname;
    if (trimmedBio) {
        // 后端字段名按 "bio" 传
        parameters[@"bio"] = trimmedBio;
    }

    NSLog(@"📡 更新用户资料请求: url=%@ params=%@", url, parameters);

    [network PUT:url
        parameters:parameters
           headers:headers
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSLog(@"✅ 更新用户资料响应: %@", responseObject);
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            if (completion) {
                NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                                 code:-12
                                             userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
                completion(nil, e);
            }
            return;
        }

        YALAuthUserModel *user = nil;
        NSError *error = nil;
        BOOL ok = [self handleAuthResponse:responseObject successData:&user error:&error isLogin:NO];
        if (ok && user) {
            // 兜底：响应缺字段时用旧值/请求值补齐，避免 Mine 页丢 ID/bio
            if ((user.userId <= 0) && previousUser.userId > 0) {
                user.userId = previousUser.userId;
            }
            if ((user.username == nil || user.username.length == 0) && previousUser.username.length > 0) {
                user.username = previousUser.username;
            }
            if (trimmedBio && (user.bio == nil || user.bio.length == 0)) {
                user.bio = trimmedBio;
            }
            if ((user.avatar == nil || user.avatar.length == 0) && previousUser.avatar.length > 0) {
                user.avatar = previousUser.avatar;
            }

            // 更新资料后同步 currentUser（这样 Mine 页能立刻刷新）
            self.currentUser = user;
            if (completion) {
                completion(user, nil);
            }
        } else {
            if (completion) {
                completion(nil, error ?: [NSError errorWithDomain:@"YALAuthManager"
                                                               code:-13
                                                           userInfo:@{NSLocalizedDescriptionKey: @"保存失败"}]);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 更新用户资料失败(网络层): %@", error);
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)updateUserInfoWithNickname:(NSString * _Nonnull)nickname
                           avatar:(NSString * _Nonnull)avatar
                       completion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion {
    NSString *trimmedNickname = [nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedNickname.length == 0) {
        if (completion) {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:-20
                                         userInfo:@{NSLocalizedDescriptionKey: @"昵称不能为空"}];
            completion(nil, e);
        }
        return;
    }
    if (avatar.length == 0) {
        if (completion) {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:-21
                                         userInfo:@{NSLocalizedDescriptionKey: @"头像不能为空"}];
            completion(nil, e);
        }
        return;
    }

    // 保存旧 userId/username：后端可能只返回 nickname/avatar，不返回 user_id
    YALAuthUserModel *previousUser = self.currentUser;

    NSDictionary *headers = [self getAuthHeadersWithToken];
    if (![headers isKindOfClass:[NSDictionary class]] || headers.count == 0) {
        if (completion) {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:-22
                                         userInfo:@{NSLocalizedDescriptionKey: @"未登录或token缺失"}];
            completion(nil, e);
        }
        return;
    }

    YALNetworkManager *network = [YALNetworkManager shareManager];
    // 文档：PUT /user/info
    NSString *url = [NSString stringWithFormat:@"%@/user/info", kYALAPIBaseURL];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"nickname"] = trimmedNickname;
    parameters[@"avatar"] = avatar;

    NSLog(@"📡 更新用户信息请求: url=%@ params=%@", url, parameters);

    [network PUT:url
        parameters:parameters
           headers:headers
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSLog(@"✅ 更新用户信息响应: %@", responseObject);
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            if (completion) {
                NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                                 code:-23
                                             userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
                completion(nil, e);
            }
            return;
        }

        YALAuthUserModel *user = nil;
        NSError *error = nil;
        BOOL ok = [self handleAuthResponse:responseObject successData:&user error:&error isLogin:NO];
        if (ok && user) {
            if ((user.userId <= 0) && previousUser.userId > 0) {
                user.userId = previousUser.userId;
            }
            if ((user.username == nil || user.username.length == 0) && previousUser.username.length > 0) {
                user.username = previousUser.username;
            }
            if ((user.avatar == nil || user.avatar.length == 0)) {
                user.avatar = avatar;
            }
            if ((user.nickname == nil || user.nickname.length == 0)) {
                user.nickname = trimmedNickname;
            }

            self.currentUser = user;
            if (completion) {
                completion(user, nil);
            }
        } else {
            if (completion) {
                completion(nil, error ?: [NSError errorWithDomain:@"YALAuthManager"
                                                               code:-24
                                                           userInfo:@{NSLocalizedDescriptionKey: @"保存失败"}]);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 更新用户信息失败(网络层): %@", error);
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)updateUserInfoWithNickname:(NSString * _Nonnull)nickname
                              avatar:(NSString * _Nullable)avatar
                                 bio:(NSString * _Nullable)bio
                       completion:(void (^ _Nonnull)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion {
    NSString *trimmedNickname = [nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimmedAvatar = nil;
    if (avatar && [avatar isKindOfClass:[NSString class]]) {
        trimmedAvatar = [avatar stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedAvatar.length == 0) {
            trimmedAvatar = nil;
        }
    }

    NSString *trimmedBio = nil;
    if (bio) {
        trimmedBio = [bio stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedBio.length == 0) {
            trimmedBio = nil;
        }
    }

    // 保存旧 userId/username：后端可能只返回 nickname/avatar，不返回 user_id/bio
    YALAuthUserModel *previousUser = self.currentUser;

    if (trimmedNickname.length == 0) {
        if (completion) {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:-100
                                         userInfo:@{NSLocalizedDescriptionKey: @"昵称不能为空"}];
            completion(nil, e);
        }
        return;
    }

    NSDictionary *headers = [self getAuthHeadersWithToken];
    if (![headers isKindOfClass:[NSDictionary class]] || headers.count == 0) {
        if (completion) {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:-101
                                         userInfo:@{NSLocalizedDescriptionKey: @"未登录或token缺失"}];
            completion(nil, e);
        }
        return;
    }

    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/user/info", kYALAPIBaseURL];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"nickname"] = trimmedNickname;
    if (trimmedAvatar) {
        parameters[@"avatar"] = trimmedAvatar;
    }
    if (trimmedBio) {
        parameters[@"bio"] = trimmedBio;
    }

    NSLog(@"📡 一次更新用户资料请求: url=%@ params=%@", url, parameters);

    [network PUT:url
        parameters:parameters
           headers:headers
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSLog(@"✅ 一次更新用户资料响应: %@", responseObject);

        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            if (completion) {
                NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                                 code:-102
                                             userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
                completion(nil, e);
            }
            return;
        }

        YALAuthUserModel *user = nil;
        NSError *error = nil;
        BOOL ok = [self handleAuthResponse:responseObject successData:&user error:&error isLogin:NO];
        if (ok && user) {
            // 兜底：后端不回 bio/userId/username 时用旧值/请求值补齐
            if ((user.userId <= 0) && previousUser.userId > 0) {
                user.userId = previousUser.userId;
            }
            if ((user.username == nil || user.username.length == 0) && previousUser.username.length > 0) {
                user.username = previousUser.username;
            }
            if (trimmedBio && (user.bio == nil || user.bio.length == 0)) {
                user.bio = trimmedBio;
            }
            if (trimmedAvatar && (user.avatar == nil || user.avatar.length == 0)) {
                user.avatar = trimmedAvatar;
            }
            if ((user.nickname == nil || user.nickname.length == 0)) {
                user.nickname = trimmedNickname;
            }

            self.currentUser = user;
            if (completion) {
                completion(user, nil);
            }
        } else {
            if (completion) {
                completion(nil, error ?: [NSError errorWithDomain:@"YALAuthManager"
                                                               code:-103
                                                           userInfo:@{NSLocalizedDescriptionKey: @"保存失败"}]);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 一次更新用户资料失败(网络层): %@", error);
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)updatePasswordWithOldPassword:(NSString * _Nonnull)oldPassword
                          newPassword:(NSString * _Nonnull)newPassword
                        repeatPassword:(NSString * _Nonnull)repeatPassword
                            completion:(void (^ _Nonnull)(BOOL success, NSString * _Nullable message, NSError * _Nullable error))completion {
    NSString *oldP = [oldPassword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *newP = [newPassword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *repeatP = [repeatPassword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (oldP.length == 0 || newP.length == 0 || repeatP.length == 0) {
        if (completion) {
            completion(NO, @"密码不能为空", [NSError errorWithDomain:@"YALAuthManager"
                                                                code:-30
                                                            userInfo:@{NSLocalizedDescriptionKey: @"密码不能为空"}]);
        }
        return;
    }
    if (![newP isEqualToString:repeatP]) {
        if (completion) {
            completion(NO, @"两次新密码不一致", [NSError errorWithDomain:@"YALAuthManager"
                                                                    code:-31
                                                                userInfo:@{NSLocalizedDescriptionKey: @"两次新密码不一致"}]);
        }
        return;
    }

    NSDictionary *headers = [self getAuthHeadersWithToken];
    if (![headers isKindOfClass:[NSDictionary class]] || headers.count == 0) {
        if (completion) {
            completion(NO, @"未登录或token缺失", [NSError errorWithDomain:@"YALAuthManager"
                                                                     code:-32
                                                                 userInfo:@{NSLocalizedDescriptionKey: @"未登录或token缺失"}]);
        }
        return;
    }

    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/user/info/updatepassword", kYALAPIBaseURL];
    NSDictionary *parameters = @{
        @"old_password": oldP,
        @"new_password": newP,
        @"repeat_passwd": repeatP
    };

    NSLog(@"📡 修改密码请求: url=%@ params=%@", url, parameters);

    [network PUT:url
        parameters:parameters
           headers:headers
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSLog(@" 修改密码响应: %@", responseObject);
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            if (completion) {
                NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                                 code:-33
                                             userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
                completion(NO, @"无效的响应格式", e);
            }
            return;
        }

        NSDictionary *dic = (NSDictionary *)responseObject;
        NSInteger code = [dic[@"code"] respondsToSelector:@selector(integerValue)] ? [dic[@"code"] integerValue] : -1;
        NSString *msg = [dic[@"msg"] isKindOfClass:[NSString class]] ? dic[@"msg"] : @"";

        if (code == 200) {
            if (completion) {
                completion(YES, msg.length > 0 ? msg : @"更新成功", nil);
            }
        } else {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:code
                                         userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"更新失败"}];
            if (completion) {
                completion(NO, msg.length > 0 ? msg : @"更新失败", e);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSLog(@" 修改密码失败(网络层): %@", error);
        if (completion) {
            completion(NO, @"网络错误", error);
        }
    }];
}

@end
