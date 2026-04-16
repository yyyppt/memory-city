//
//  YALNetworkManager.m
//  MemoryCity
//
//  Created by mac on 2026/3/23.
//

#import "YALNetworkManager.h"

#import "YALAuthManager.h"

NSString * const YALAPIBaseURLString = @"http://8.137.158.7:9000/api";
NSString * const YALAPIRootURLString = @"http://8.137.158.7:9000/api";

@interface YALStreamSessionDelegate : NSObject <NSURLSessionDataDelegate>

@property (nonatomic, copy, nullable) void (^responseHandler)(NSHTTPURLResponse *response);
@property (nonatomic, copy, nullable) void (^dataHandler)(NSData *chunk);
@property (nonatomic, copy, nullable) void (^completionHandler)(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error);
@property (nonatomic, strong, nullable) NSHTTPURLResponse *response;

@end

@implementation YALStreamSessionDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    (void)dataTask;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.response = (NSHTTPURLResponse *)response;
        if (self.responseHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.responseHandler(self.response);
            });
        }
    }
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    (void)session;
    (void)dataTask;
    if (data.length == 0 || !self.dataHandler) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataHandler(data);
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    (void)task;
    void (^completion)(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) = self.completionHandler;
    NSHTTPURLResponse *response = self.response;
    [session finishTasksAndInvalidate];
    if (!completion) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(response, error);
    });
}

@end

@interface YALNetworkManager ()

@property (nonatomic, assign) BOOL isRefreshingToken;
@property (nonatomic, strong) NSMutableArray *pendingRefreshBlocks;
@property (nonatomic, strong) NSMapTable<NSURLSessionTask *, id> *streamDelegates;

@end

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
        self.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", @"text/html", nil];
        self.sessionManager.requestSerializer.HTTPShouldHandleCookies = YES;
        [NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
        self.pendingRefreshBlocks = [NSMutableArray array];
        self.streamDelegates = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (void)GET:(NSString *_Nonnull)URLString
 parameters:(nullable id)parameters
    headers:(nullable NSDictionary<NSString *,NSString *> *)headers
   progress:(nullable void (^)(NSProgress * _Nonnull))downloadProgress
    success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
    failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    [self performRequestWithMethod:@"GET"
                         URLString:URLString
                        parameters:parameters
                           headers:headers
                    uploadProgress:nil
                  downloadProgress:downloadProgress
                retryOnAuthFailure:YES
                           success:success
                           failure:failure];
}

- (void)POST:(NSString *_Nonnull)URLString
  parameters:(nullable id)parameters
     headers:(nullable NSDictionary<NSString *, NSString *> *)headers
    progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
     success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
     failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    [self performRequestWithMethod:@"POST"
                         URLString:URLString
                        parameters:parameters
                           headers:headers
                    uploadProgress:uploadProgress
                  downloadProgress:nil
                retryOnAuthFailure:YES
                           success:success
                           failure:failure];
}

- (void)PUT:(NSString *_Nonnull)URLString
 parameters:(nullable id)parameters
    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
    success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
    failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    [self performRequestWithMethod:@"PUT"
                         URLString:URLString
                        parameters:parameters
                           headers:headers
                    uploadProgress:nil
                  downloadProgress:nil
                retryOnAuthFailure:YES
                           success:success
                           failure:failure];
}

- (void)DELETE:(NSString *_Nonnull)URLString
    parameters:(nullable id)parameters
       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
       success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
       failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    [self performRequestWithMethod:@"DELETE"
                         URLString:URLString
                        parameters:parameters
                           headers:headers
                    uploadProgress:nil
                  downloadProgress:nil
                retryOnAuthFailure:YES
                           success:success
                           failure:failure];
}

- (NSURLSessionDataTask *)streamPOST:(NSString *_Nonnull)URLString
                          parameters:(nullable id)parameters
                             headers:(nullable NSDictionary<NSString *,NSString *> *)headers
                     responseHandler:(nullable void (^)(NSHTTPURLResponse * _Nonnull response))responseHandler
                         dataHandler:(nullable void (^)(NSData * _Nonnull chunk))dataHandler
                          completion:(nullable void (^)(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completion {
    NSError *requestError = nil;
    NSMutableURLRequest *request = [self requestWithMethod:@"POST"
                                                 URLString:URLString
                                                parameters:parameters
                                                   headers:[self mergedHeadersForURLString:URLString headers:headers]
                                                     error:&requestError];
    if (requestError || !request) {
        if (completion) {
            NSError *error = requestError ?: [NSError errorWithDomain:@"YALNetworkManager"
                                                                 code:-1
                                                             userInfo:@{NSLocalizedDescriptionKey: @"请求创建失败"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
        }
        return nil;
    }

    YALStreamSessionDelegate *delegate = [[YALStreamSessionDelegate alloc] init];
    delegate.responseHandler = responseHandler;
    delegate.dataHandler = dataHandler;
    __weak typeof(self) weakSelf = self;
    __block NSURLSessionDataTask *task = nil;
    delegate.completionHandler = ^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && task) {
            @synchronized (strongSelf.streamDelegates) {
                [strongSelf.streamDelegates removeObjectForKey:task];
            }
        }
        if (completion) {
            completion(response, error);
        }
    };

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    configuration.timeoutIntervalForRequest = self.sessionManager.requestSerializer.timeoutInterval;
    configuration.timeoutIntervalForResource = MAX(configuration.timeoutIntervalForRequest, 60.0);
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:nil];
    task = [session dataTaskWithRequest:request];
    @synchronized (self.streamDelegates) {
        [self.streamDelegates setObject:delegate forKey:task];
    }
    [task resume];
    return task;
}

- (void)performRequestWithMethod:(NSString *)method
                       URLString:(NSString *)URLString
                      parameters:(nullable id)parameters
                         headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                  uploadProgress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
                downloadProgress:(nullable void (^)(NSProgress * _Nonnull))downloadProgress
              retryOnAuthFailure:(BOOL)retryOnAuthFailure
                         success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
                         failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    NSError *requestError = nil;
    NSMutableURLRequest *request = [self requestWithMethod:method
                                                 URLString:URLString
                                                parameters:parameters
                                                   headers:[self mergedHeadersForURLString:URLString headers:headers]
                                                     error:&requestError];
    if (requestError || !request) {
        [self dispatchFailure:failure task:nil error:(requestError ?: [NSError errorWithDomain:@"YALNetworkManager"
                                                                                           code:-1
                                                                                       userInfo:@{NSLocalizedDescriptionKey: @"请求创建失败"}])];
        return;
    }

    __weak typeof(self) weakSelf = self;
    __block NSURLSessionDataTask *task = nil;
    task = [self.sessionManager dataTaskWithRequest:request
                                     uploadProgress:uploadProgress
                                   downloadProgress:downloadProgress
                                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        BOOL isUnauthorized = [strongSelf responseIndicatesUnauthorizedWithTask:task
                                                                 responseObject:responseObject
                                                                          error:error];
        BOOL canRetry = retryOnAuthFailure && ![strongSelf shouldSkipAuthRefreshForURLString:URLString];
        if (isUnauthorized && canRetry) {
            [strongSelf enqueueTokenRefreshWithCompletion:^(BOOL refreshSuccess) {
                if (refreshSuccess) {
                    [strongSelf performRequestWithMethod:method
                                               URLString:URLString
                                              parameters:parameters
                                                 headers:headers
                                          uploadProgress:uploadProgress
                                        downloadProgress:downloadProgress
                                      retryOnAuthFailure:NO
                                                 success:success
                                                 failure:failure];
                    return;
                }

                NSError *authError = [strongSelf authFailureErrorFromTask:task responseObject:responseObject fallback:error];
                [strongSelf dispatchFailure:failure task:task error:authError];
            }];
            return;
        }

        if (error) {
            [strongSelf dispatchFailure:failure task:task error:error];
            return;
        }

        [strongSelf dispatchSuccess:success task:task responseObject:responseObject];
    }];
    [task resume];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(nullable id)parameters
                                   headers:(NSDictionary<NSString *, NSString *> *)headers
                                     error:(NSError * __autoreleasing *)error {
    BOOL isDeleteWithJSONBody = [method isEqualToString:@"DELETE"] &&
                                [parameters isKindOfClass:[NSDictionary class]] &&
                                [(NSDictionary *)parameters count] > 0;
    NSMutableURLRequest *request = nil;

    if (isDeleteWithJSONBody) {
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        request.HTTPMethod = method;
        request.timeoutInterval = self.sessionManager.requestSerializer.timeoutInterval;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:error];
        if (!jsonData) {
            return nil;
        }
        request.HTTPBody = jsonData;
    } else {
        request = [self.sessionManager.requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
        if (!request) {
            return nil;
        }
    }

    [headers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, __unused BOOL * _Nonnull stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    return request;
}

- (NSDictionary<NSString *, NSString *> *)mergedHeadersForURLString:(NSString *)URLString
                                                            headers:(NSDictionary<NSString *, NSString *> *)headers {
    NSMutableDictionary<NSString *, NSString *> *merged = [NSMutableDictionary dictionary];
    if ([headers isKindOfClass:[NSDictionary class]]) {
        [merged addEntriesFromDictionary:headers];
    }

    if (![self shouldAttachAuthHeadersForURLString:URLString]) {
        return [merged copy];
    }

    NSDictionary<NSString *, NSString *> *authHeaders = [[YALAuthManager sharedManager] getAuthHeadersWithToken];
    [authHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, __unused BOOL * _Nonnull stop) {
        // 重试请求必须使用当前最新 token，不能沿用首次请求里已经过期的 Authorization 头。
        if ([key isEqualToString:@"Authorization"] || [key isEqualToString:@"Refresh-Authorization"]) {
            merged[key] = obj;
        } else if (merged[key].length == 0) {
            merged[key] = obj;
        }
    }];
    return [merged copy];
}

- (BOOL)shouldAttachAuthHeadersForURLString:(NSString *)URLString {
    NSString *path = URLString.lowercaseString ?: @"";
    if ([path containsString:@"/user/login"] ||
        [path containsString:@"/user/register"] ||
        [path containsString:@"/user/password/forgot/"] ||
        [path containsString:@"/user/password/forgot"] ||
        [path containsString:@"/forgetpasswd/"] ||
        [path containsString:@"/forgetpasswd"]) {
        return NO;
    }
    return YES;
}

- (BOOL)shouldSkipAuthRefreshForURLString:(NSString *)URLString {
    NSString *path = URLString.lowercaseString ?: @"";
    return [path containsString:@"/user/refresh"];
}

- (BOOL)responseIndicatesUnauthorizedWithTask:(NSURLSessionDataTask *)task
                               responseObject:(id)responseObject
                                        error:(NSError *)error {
    NSInteger statusCode = [self statusCodeFromTask:task];
    if (statusCode == 401) {
        return YES;
    }

    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        id codeObj = ((NSDictionary *)responseObject)[@"code"];
        NSInteger businessCode = [codeObj respondsToSelector:@selector(integerValue)] ? [codeObj integerValue] : NSNotFound;
        if (businessCode == 401) {
            return YES;
        }
    }

    NSInteger responseCode = [error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
    return responseCode == 401;
}

- (NSInteger)statusCodeFromTask:(NSURLSessionDataTask *)task {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return NSNotFound;
    }
    return response.statusCode;
}

- (NSError *)authFailureErrorFromTask:(NSURLSessionDataTask *)task
                        responseObject:(id)responseObject
                              fallback:(NSError *)fallback {
    NSString *message = @"登录状态已失效，请重新登录";
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        id msgObj = ((NSDictionary *)responseObject)[@"msg"];
        if ([msgObj isKindOfClass:[NSString class]] && [((NSString *)msgObj) length] > 0) {
            message = (NSString *)msgObj;
        }
    } else if (fallback.localizedDescription.length > 0) {
        message = fallback.localizedDescription;
    }

    NSInteger code = [self statusCodeFromTask:task];
    if (code == NSNotFound) {
        code = fallback.code != 0 ? fallback.code : 401;
    }
    return [NSError errorWithDomain:@"YALNetworkManager"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

- (void)enqueueTokenRefreshWithCompletion:(void (^)(BOOL success))completion {
    if (!completion) {
        return;
    }

    BOOL shouldStartRefresh = NO;
    @synchronized (self) {
        [self.pendingRefreshBlocks addObject:[completion copy]];
        if (!self.isRefreshingToken) {
            self.isRefreshingToken = YES;
            shouldStartRefresh = YES;
        }
    }

    if (!shouldStartRefresh) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[YALAuthManager sharedManager] refreshAccessTokenWithCompletion:^(BOOL success) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        if (!success && ![[YALAuthManager sharedManager] hasLoggedInSession]) {
            [[YALAuthManager sharedManager] clearAuthSession];
        }

        NSArray *callbacks = nil;
        @synchronized (strongSelf) {
            strongSelf.isRefreshingToken = NO;
            callbacks = [strongSelf.pendingRefreshBlocks copy];
            [strongSelf.pendingRefreshBlocks removeAllObjects];
        }

        for (void (^callback)(BOOL) in callbacks) {
            callback(success);
        }
    }];
}

- (void)dispatchSuccess:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                   task:(NSURLSessionDataTask *)task
         responseObject:(id)responseObject {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            success(task, responseObject);
        }
    });
}

- (void)dispatchFailure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
                   task:(NSURLSessionDataTask *)task
                  error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (failure) {
            failure(task, error);
        }
    });
}

@end
