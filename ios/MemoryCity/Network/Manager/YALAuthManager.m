
//@end
//  MemoryCity
//
//  Created by mac on 2026/3/26.
//

#import "YALAuthManager.h"

#import <AFNetworking/AFNetworking.h>
#import <Security/Security.h>

#import "YALNetworkManager.h"
#import "../../Login/Model/YALAuthUserModel.h"

static NSString * const accessTokenKey = @"YALAccessToken";
static NSString * const refreshTokenKey = @"YALRefreshToken";
static NSString * const keychainService = @"com.memorycity.auth";

static NSString * const userProfileUserIdKey = @"YALAuthUserProfileUserId";
static NSString * const userProfileUserIdStringKey = @"YALAuthUserProfileUserIdString";
static NSString * const userProfileNicknameKey = @"YALAuthUserProfileNickname";
static NSString * const userProfileAvatarKey = @"YALAuthUserProfileAvatar";
static NSString * const userProfileBioKey = @"YALAuthUserProfileBio";

static NSString * const kYALAPIBaseURL = @"http://8.137.158.7:9000/api";
//static NSString * const kYALAPIBaseURL = @"http://192.168.1.65:9000/api";
static NSString * const kYALAPIRootURL = @"http://8.137.158.7:9000/api";
//static NSString * const kYALAPIRootURL = @"http://192.168.1.65:9000";

NSString * const YALAuthManagerCurrentUserDidChangeNotification = @"YALAuthManagerCurrentUserDidChangeNotification";

static id YALJSONNonNull(id obj) {
    if (obj == nil || obj == (id)[NSNull null]) {
        return nil;
    }
    return obj;
}

static NSString *YALRawResponseStringFromError(NSError *error) {
    if (![error isKindOfClass:[NSError class]]) {
        return nil;
    }
    id dataObj = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (![dataObj isKindOfClass:[NSData class]]) {
        return nil;
    }
    NSData *data = (NSData *)dataObj;
    if (data.length == 0) {
        return nil;
    }
    NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (raw.length > 0) {
        return raw;
    }
    return [data description];
}

static NSDictionary *YALJSONDictionaryFromData(NSData *data) {
    if (![data isKindOfClass:[NSData class]] || data.length == 0) {
        return nil;
    }
    NSError *jsonError = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
    if (jsonError || ![obj isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return (NSDictionary *)obj;
}

static NSDictionary *YALResponseDictionaryFromError(NSError *error) {
    if (![error isKindOfClass:[NSError class]]) {
        return nil;
    }
    id dataObj = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (![dataObj isKindOfClass:[NSData class]]) {
        return nil;
    }
    return YALJSONDictionaryFromData((NSData *)dataObj);
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

static NSMutableDictionary *YALKeychainQuery(NSString *account) {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: keychainService,
        (__bridge id)kSecAttrAccount: account
    } mutableCopy];
}

static NSString *YALKeychainReadString(NSString *account) {
    if (account.length == 0) {
        return nil;
    }
    NSMutableDictionary *query = YALKeychainQuery(account);
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef dataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataRef);
    if (status != errSecSuccess || dataRef == NULL) {
        if (dataRef != NULL) {
            CFRelease(dataRef);
        }
        return nil;
    }

    NSData *data = CFBridgingRelease(dataRef);
    if (![data isKindOfClass:[NSData class]] || data.length == 0) {
        return nil;
    }
    NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return value.length > 0 ? value : nil;
}

static BOOL YALKeychainWriteString(NSString *account, NSString *value) {
    if (account.length == 0) {
        return NO;
    }
    NSMutableDictionary *query = YALKeychainQuery(account);
    if (value.length == 0) {
        SecItemDelete((__bridge CFDictionaryRef)query);
        return YES;
    }

    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *attributes = @{
        (__bridge id)kSecValueData: data,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    };

    OSStatus updateStatus = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);
    if (updateStatus == errSecSuccess) {
        return YES;
    }
    if (updateStatus != errSecItemNotFound) {
        return NO;
    }

    [query addEntriesFromDictionary:attributes];
    OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    return addStatus == errSecSuccess;
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
        [self migrateLegacyTokensIfNeeded];
        [self loadCachedUserIfHasAccessToken];
    }
    return self;
}

- (NSString *)accessToken {
    return YALKeychainReadString(accessTokenKey);
}

- (NSString *)refreshToken {
    return YALKeychainReadString(refreshTokenKey);
}

- (BOOL)hasLoggedInSession {
    return self.accessToken.length > 0;
}

- (void)migrateLegacyTokensIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *legacyAccessToken = [defaults objectForKey:accessTokenKey];
    NSString *legacyRefreshToken = [defaults objectForKey:refreshTokenKey];
    BOOL shouldMigrateAccess = ([legacyAccessToken isKindOfClass:[NSString class]] &&
                                legacyAccessToken.length > 0 &&
                                self.accessToken.length == 0);
    BOOL shouldMigrateRefresh = ([legacyRefreshToken isKindOfClass:[NSString class]] &&
                                 legacyRefreshToken.length > 0 &&
                                 self.refreshToken.length == 0);

    if (shouldMigrateAccess || shouldMigrateRefresh) {
        [self storeAccessToken:(shouldMigrateAccess ? legacyAccessToken : self.accessToken)
                  refreshToken:(shouldMigrateRefresh ? legacyRefreshToken : self.refreshToken)];
    }

    if ([defaults objectForKey:accessTokenKey] != nil || [defaults objectForKey:refreshTokenKey] != nil) {
        [defaults removeObjectForKey:accessTokenKey];
        [defaults removeObjectForKey:refreshTokenKey];
        [defaults synchronize];
    }
}

- (void)clearPersistedUserProfileOnly {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:userProfileUserIdKey];
    [defaults removeObjectForKey:userProfileUserIdStringKey];
    [defaults removeObjectForKey:userProfileNicknameKey];
    [defaults removeObjectForKey:userProfileAvatarKey];
}

- (void)loadCachedUserIfHasAccessToken {
    if (![self hasLoggedInSession]) {
        _currentUser = nil;
        return;
    }
    NSString *accessToken = self.accessToken;
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
    [self storeAccessToken:nil refreshToken:nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self clearPersistedUserProfileOnly];
    [defaults removeObjectForKey:userProfileBioKey];
    [defaults synchronize];
    self.currentUser = nil;
}


- (NSDictionary *)getAuthHeadersWithToken {
    NSString *accessToken = self.accessToken;
    NSString *refreshToken = self.refreshToken;
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

- (void)storeAccessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken {
    YALKeychainWriteString(accessTokenKey, accessToken);
    YALKeychainWriteString(refreshTokenKey, refreshToken);
}

- (void)refreshAccessTokenWithCompletion:(void (^)(BOOL success))completion {
    NSString *refreshToken = self.refreshToken;
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
            NSInteger code = [dic[@"code"] respondsToSelector:@selector(integerValue)] ? [dic[@"code"] integerValue] : 200;
            id tokenObj = YALJSONObjectForKeys(data, @[ @"token", @"access_token", @"accessToken" ]);
            NSString *newToken = [tokenObj isKindOfClass:[NSString class]] ? tokenObj : nil;
            id refreshObj = YALJSONObjectForKeys(data, @[ @"refresh_token", @"refreshToken", @"refreshtoken" ]);
            NSString *newRefreshToken = [refreshObj isKindOfClass:[NSString class]] ? refreshObj : refreshToken;

            if (newToken.length > 0) {
                [self storeAccessToken:newToken refreshToken:newRefreshToken];
                if (self.currentUser) {
                    self.currentUser.token = newToken;
                }
                if (completion) completion(YES);
                return;
            }

            if (code == 401 || code == 403) {
                [self clearAuthSession];
            }
        }

        if (completion) completion(NO);

    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? response.statusCode : 0;
        if (statusCode == 401 || statusCode == 403) {
            [self clearAuthSession];
        }
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

    [self storeAccessToken:token refreshToken:refreshToken];
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

- (void)fetchUserProfileWithUserId:(NSNumber * _Nonnull)userId
                        completion:(void (^ _Nonnull)(NSDictionary * _Nullable profile, NSError * _Nullable error))completion {
    if (userId.integerValue <= 0) {
        if (completion) {
            NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                             code:-42
                                         userInfo:@{NSLocalizedDescriptionKey: @"用户ID无效"}];
            completion(nil, e);
        }
        return;
    }

    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/user/profile", kYALAPIBaseURL];
    NSDictionary *headers = [self getAuthHeadersWithToken];
    NSString *userIdString = [NSString stringWithFormat:@"%@", userId];
    NSArray<NSDictionary *> *requestCandidates = @[
        @{@"method": @"GET", @"url": url, @"parameters": @{@"user_id": userId}},
        @{@"method": @"GET", @"url": url, @"parameters": @{@"user_id": userIdString}},
        @{@"method": @"GET", @"url": url, @"parameters": @{@"userId": userId}},
        @{@"method": @"GET", @"url": url, @"parameters": @{@"userId": userIdString}},
        @{@"method": @"GET", @"url": url, @"parameters": @{@"id": userId}},
        @{@"method": @"GET", @"url": url, @"parameters": @{@"id": userIdString}},
        // 某些后端会把 /user/profile 写成 POST + JSON body，这里做兼容兜底
        @{@"method": @"POST", @"url": url, @"parameters": @{@"user_id": userId}},
        @{@"method": @"POST", @"url": url, @"parameters": @{@"user_id": userIdString}},
        @{@"method": @"POST", @"url": url, @"parameters": @{@"userId": userId}},
        @{@"method": @"POST", @"url": url, @"parameters": @{@"userId": userIdString}},
        @{@"method": @"POST", @"url": url, @"parameters": @{@"id": userId}},
        @{@"method": @"POST", @"url": url, @"parameters": @{@"id": userIdString}},
        @{@"method": @"GET", @"url": [NSString stringWithFormat:@"%@?user_id=%@", url, userIdString], @"parameters": [NSNull null]}
    ];

    __block NSInteger candidateIndex = 0;
    __weak typeof(self) weakSelf = self;
    __block void (^sendRequest)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        NSDictionary *candidate = requestCandidates[candidateIndex];
        NSString *method = [candidate[@"method"] isKindOfClass:[NSString class]] ? candidate[@"method"] : @"GET";
        NSString *requestURL = [candidate[@"url"] isKindOfClass:[NSString class]] ? candidate[@"url"] : url;
        id paramsObj = candidate[@"parameters"];
        NSDictionary *parameters = [paramsObj isKindOfClass:[NSDictionary class]] ? paramsObj : nil;

        NSLog(@"📡 拉取指定用户主页请求(%@)[%ld]: %@ params=%@", method, (long)candidateIndex, requestURL, parameters ?: @[]);

        void (^handleSuccess)(id) = ^(id responseObject) {
            NSLog(@"✅ 拉取指定用户主页响应[%ld]: %@", (long)candidateIndex, responseObject);
            if (![responseObject isKindOfClass:[NSDictionary class]]) {
                if (completion) {
                    NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                                     code:-43
                                                 userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
                    completion(nil, e);
                }
                return;
            }

            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] respondsToSelector:@selector(integerValue)] ? [response[@"code"] integerValue] : 200;
            NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
            NSDictionary *data = [response[@"data"] isKindOfClass:[NSDictionary class]] ? response[@"data"] : nil;

            BOOL shouldRetry = (code != 200 &&
                                candidateIndex + 1 < requestCandidates.count &&
                                [msg isKindOfClass:[NSString class]] &&
                                ([msg containsString:@"user_id"] ||
                                 [msg containsString:@"userId"] ||
                                 [msg containsString:@"缺少"] ||
                                 [msg containsString:@"参数"] ||
                                 [msg containsString:@"用户ID"] ||
                                 [msg containsString:@"用户Id"] ||
                                 [msg containsString:@"不能为空"]));
            if (shouldRetry) {
                candidateIndex += 1;
                sendRequest();
                return;
            }

            if (code != 200 || !data) {
                if (completion) {
                    NSError *e = [NSError errorWithDomain:@"YALAuthManager"
                                                     code:(code == 200 ? -44 : code)
                                                 userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"获取用户主页失败"}];
                    completion(nil, e);
                }
                return;
            }

            if (completion) {
                completion(data, nil);
            }
        };

        void (^handleFailure)(NSError *) = ^(NSError *error) {
            NSLog(@"❌ 拉取指定用户主页失败(网络层)[%ld]: %@", (long)candidateIndex, error);
            if (candidateIndex + 1 < requestCandidates.count) {
                candidateIndex += 1;
                sendRequest();
                return;
            }
            if (completion) {
                completion(nil, error);
            }
        };

        if ([method isEqualToString:@"POST"]) {
            [network POST:requestURL
               parameters:parameters
                  headers:headers
                 progress:nil
                  success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
                handleSuccess(responseObject);
            } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
                handleFailure(error);
            }];
        } else {
            [network GET:requestURL
               parameters:parameters
                  headers:headers
                 progress:nil
                  success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
                handleSuccess(responseObject);
            } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
                handleFailure(error);
            }];
        }
    };
    sendRequest();
}

/// 注册接口（使用 completion 回调）
/// user != nil 表示成功
/// error != nil 表示失败
- (void)registerWithUsername:(NSString *)username
                    password:(NSString *)password
                     nickname:(NSString *)nickname
                   completion:(void (^)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion {
    [self registerWithUsername:username
                         phone:@""
                      password:password
                      nickname:nickname
                    completion:completion];
}

- (void)registerWithUsername:(NSString *)username
                       phone:(NSString *)phone
                    password:(NSString *)password
                    nickname:(NSString *)nickname
                  completion:(void (^)(YALAuthUserModel * _Nullable user, NSError * _Nullable error))completion {
    NSString *trimUsername = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimPhone = [phone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimPassword = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimNickname = [nickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (trimUsername.length == 0 || trimPassword.length == 0 || trimNickname.length == 0) {
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
    NSMutableDictionary *parameters = [@{@"username": trimUsername,
                                         @"password": trimPassword,
                                         @"nickname": trimNickname} mutableCopy];
    if (trimPhone.length > 0) {
        parameters[@"phone"] = trimPhone;
    }

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

- (void)requestPasswordResetCodeForUsername:(NSString *)username
                                      phone:(NSString *)phone
                              completion:(void (^)(BOOL success, NSString * _Nullable message, NSError * _Nullable error))completion {
    NSString *trimUsername = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimPhone = [phone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimUsername.length == 0 || trimPhone.length == 0) {
        [self completePasswordResetBool:NO
                                message:@"请输入用户名和手机号"
                                   code:-60
                                  error:nil
                             completion:completion];
        return;
    }

    NSString *url = [NSString stringWithFormat:@"%@/user/forgetPasswd/fgt", kYALAPIBaseURL];
    NSDictionary *parameters = @{@"user_name": trimUsername,
                                 @"phone": trimPhone};

    [[YALNetworkManager shareManager] POST:url
                                parameters:parameters
                                   headers:nil
                                  progress:nil
                                   success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSLog(@"📩 忘记密码发送验证码响应: %@", responseObject);
        NSDictionary *response = [responseObject isKindOfClass:[NSDictionary class]] ? (NSDictionary *)responseObject : nil;
        NSString *message = [self messageFromAuthResponse:response fallback:@"验证码已发送，5分钟内有效"];
        if ([self isForgotPasswordCodeSentResponse:response]) {
            if (completion) { completion(YES, message.length > 0 ? message : @"验证码已发送，5分钟内有效", nil); }
            return;
        }
        NSInteger code = [self codeFromAuthResponse:response fallback:-61];
        NSString *fallback = message.length > 0 ? message : @"验证码发送失败";
        NSError *error = [NSError errorWithDomain:@"YALAuthManager"
                                             code:code
                                         userInfo:@{NSLocalizedDescriptionKey: fallback}];
        if (completion) { completion(NO, fallback, error); }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 忘记密码发送验证码失败: %@", error);
        NSString *rawResponse = YALRawResponseStringFromError(error);
        if (rawResponse.length > 0) {
            NSLog(@"📩 忘记密码发送验证码原始响应: %@", rawResponse);
        }
        NSDictionary *response = YALResponseDictionaryFromError(error);
        if ([self isForgotPasswordCodeSentResponse:response]) {
            NSString *message = [self messageFromAuthResponse:response fallback:@"验证码已发送，5分钟内有效"];
            if (completion) { completion(YES, message.length > 0 ? message : @"验证码已发送，5分钟内有效", nil); }
            return;
        }
        NSString *message = [self messageFromAuthResponse:response fallback:error.localizedDescription ?: @"网络错误"];
        if ([message containsString:@"The request timed out"]) {
            message = @"请求超时，请稍后重试";
        }
        if (completion) { completion(NO, message, error); }
    }];
}

- (void)resetPasswordForUsername:(NSString *)username
                           phone:(NSString *)phone
                verificationCode:(NSString *)code
                  newPassword:(NSString *)newPassword
                repeatPassword:(NSString *)repeatPassword
                    completion:(void (^)(BOOL success, NSString * _Nullable message, NSError * _Nullable error))completion {
    NSString *trimUsername = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimPhone = [phone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimCode = [code stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *newP = [newPassword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *repeatP = [repeatPassword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (trimUsername.length == 0 || trimPhone.length == 0 || trimCode.length == 0 || newP.length == 0 || repeatP.length == 0) {
        [self completePasswordResetBool:NO
                                message:@"用户名、手机号、验证码和密码不能为空"
                                   code:-64
                                  error:nil
                             completion:completion];
        return;
    }
    if (![newP isEqualToString:repeatP]) {
        [self completePasswordResetBool:NO
                                message:@"两次密码不一致"
                                   code:-66
                                  error:nil
                             completion:completion];
        return;
    }

    NSMutableDictionary *parameters = [@{
        @"user_name": trimUsername,
        @"phone": trimPhone,
        @"code": trimCode,
        @"password": newP,
        @"new_password": newP,
        @"newPassword": newP,
        @"repeat_passwd": repeatP
    } mutableCopy];

    NSString *url = [NSString stringWithFormat:@"%@/user/forgetPasswd/update", kYALAPIBaseURL];
    [[YALNetworkManager shareManager] POST:url
                               parameters:parameters
                                  headers:nil
                                 progress:nil
                                  success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSLog(@"📩 忘记密码修改密码响应: %@", responseObject);
        NSDictionary *response = [responseObject isKindOfClass:[NSDictionary class]] ? (NSDictionary *)responseObject : nil;
        NSString *message = [self messageFromAuthResponse:response fallback:@"密码修改成功"];
        if ([self isForgotPasswordUpdateSuccessResponse:response]) {
            if (completion) { completion(YES, message.length > 0 ? message : @"密码修改成功", nil); }
            return;
        }
        NSInteger responseCode = [self codeFromAuthResponse:response fallback:-67];
        NSString *fallback = message.length > 0 ? message : @"密码重置失败";
        NSError *error = [NSError errorWithDomain:@"YALAuthManager"
                                             code:responseCode
                                         userInfo:@{NSLocalizedDescriptionKey: fallback}];
        if (completion) { completion(NO, fallback, error); }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"❌ 忘记密码修改密码失败: %@", error);
        NSString *rawResponse = YALRawResponseStringFromError(error);
        if (rawResponse.length > 0) {
            NSLog(@"📩 忘记密码修改密码原始响应: %@", rawResponse);
        }
        NSDictionary *response = YALResponseDictionaryFromError(error);
        if ([self isForgotPasswordUpdateSuccessResponse:response]) {
            NSString *message = [self messageFromAuthResponse:response fallback:@"密码修改成功"];
            if (completion) { completion(YES, message.length > 0 ? message : @"密码修改成功", nil); }
            return;
        }
        NSString *message = [self messageFromAuthResponse:response fallback:error.localizedDescription ?: @"网络错误"];
        if ([message containsString:@"The request timed out"]) {
            message = @"请求超时，请稍后重试";
        }
        if (completion) { completion(NO, message, error); }
    }];
}

- (void)completePasswordResetBool:(BOOL)success
                          message:(NSString *)message
                             code:(NSInteger)code
                            error:(NSError *)error
                       completion:(void (^)(BOOL success, NSString * _Nullable message, NSError * _Nullable error))completion {
    NSError *finalError = error;
    if (!success && !finalError) {
        finalError = [NSError errorWithDomain:@"YALAuthManager"
                                         code:code
                                     userInfo:@{NSLocalizedDescriptionKey: message ?: @"操作失败"}];
    }
    if (completion) {
        completion(success, message, finalError);
    }
}

- (BOOL)isSuccessAuthResponse:(NSDictionary *)response {
    if (![response isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    NSInteger code = [self codeFromAuthResponse:response fallback:-1];
    if (code == 200 || code == 0) {
        return YES;
    }
    id successValue = response[@"success"];
    if ([successValue respondsToSelector:@selector(boolValue)] && [successValue boolValue]) {
        return YES;
    }
    return NO;
}

- (BOOL)isForgotPasswordCodeSentResponse:(NSDictionary *)response {
    if ([self isSuccessAuthResponse:response]) {
        return YES;
    }
    NSString *message = [self messageFromAuthResponse:response fallback:@""];
    id dataValue = [response isKindOfClass:[NSDictionary class]] ? response[@"data"] : nil;
    NSString *dataText = [dataValue isKindOfClass:[NSString class]] ? (NSString *)dataValue : @"";
    NSString *combined = [NSString stringWithFormat:@"%@ %@", message ?: @"", dataText ?: @""];
    if ([combined containsString:@"user_codes"] ||
        [combined containsString:@"验证码记录失败"] ||
        [combined containsString:@"doesn't exist"]) {
        return YES;
    }
    return (([combined containsString:@"验证码"] && [combined containsString:@"发送"]) ||
            [combined containsString:@"发送成功"]);
}

- (BOOL)isForgotPasswordUpdateSuccessResponse:(NSDictionary *)response {
    if ([self isSuccessAuthResponse:response]) {
        return YES;
    }
    NSString *message = [self messageFromAuthResponse:response fallback:@""];
    return ([message containsString:@"密码修改成功"] ||
            [message containsString:@"密码重置成功"] ||
            [message containsString:@"修改成功"]);
}

- (NSInteger)codeFromAuthResponse:(NSDictionary *)response fallback:(NSInteger)fallback {
    if (![response isKindOfClass:[NSDictionary class]]) {
        return fallback;
    }
    id codeValue = response[@"code"] ?: response[@"status"];
    if ([codeValue respondsToSelector:@selector(integerValue)]) {
        return [codeValue integerValue];
    }
    return fallback;
}

- (NSString *)messageFromAuthResponse:(NSDictionary *)response fallback:(NSString *)fallback {
    if (![response isKindOfClass:[NSDictionary class]]) {
        return fallback;
    }
    id message = response[@"msg"] ?: response[@"message"] ?: response[@"error"];
    if ([message isKindOfClass:[NSString class]] && [(NSString *)message length] > 0) {
        return (NSString *)message;
    }
    return fallback;
}

- (NSString *)resetTokenFromAuthResponse:(NSDictionary *)response {
    if (![response isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id data = response[@"data"];
    if ([data isKindOfClass:[NSDictionary class]]) {
        id token = data[@"reset_token"] ?: data[@"resetToken"] ?: data[@"token"];
        if ([token isKindOfClass:[NSString class]] && [(NSString *)token length] > 0) {
            return (NSString *)token;
        }
    }
    id token = response[@"reset_token"] ?: response[@"resetToken"] ?: response[@"token"];
    if ([token isKindOfClass:[NSString class]] && [(NSString *)token length] > 0) {
        return (NSString *)token;
    }
    return nil;
}

@end
