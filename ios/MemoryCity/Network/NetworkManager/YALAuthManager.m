//
//  YALAuthManager.m
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

static NSString * const kYALAPIBaseURL = @"http://8.137.158.7:9000/api";

@implementation YALAuthManager

+ (instancetype)sharedManager {
    static YALAuthManager *authManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        authManager = [[YALAuthManager alloc] init];
    });
    return authManager;
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

//- (void)saveTokensFromLoginData:(NSDictionary *)data {
//    NSString *token = nil;
//    if ([data[@"token"] isKindOfClass:[NSString class]]) {
//        token = data[@"token"];
//    }
//    if (!data[@"])
//}

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
    id userIdObj = data[@"user_id"];
    if ([userIdObj respondsToSelector:@selector(integerValue)]) {
        user.userId = [userIdObj integerValue];
    }

    id nicknameObj = data[@"nickname"];
    user.nickname = [nicknameObj isKindOfClass:[NSString class]] ? nicknameObj : nil;

    id avatarObj = data[@"avatar"];
    user.avatar = [avatarObj isKindOfClass:[NSString class]] ? avatarObj : nil;

    // 只有登录时才设置token和保存token
    if (isLogin) {
        id tokenObj = data[@"token"];
        user.token = [tokenObj isKindOfClass:[NSString class]] ? tokenObj : nil;
        [self saveTokensFromLoginData:data];
    }

    if (outUser) {
        *outUser = user;
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
    NSDictionary *headers = [self authHeadersForLoginRequiredRequest];

    [network POST:url
        parameters:parameters
           headers:headers
           progress:nil
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        YALAuthUserModel *user = nil;
        NSError *error = nil;
        BOOL ok = [self handleAuthResponse:responseObject successData:&user error:&error isLogin:YES];
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

@end
