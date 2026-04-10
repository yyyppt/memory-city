//
//  YALTimelineManager.m
//  MemoryCity
//
//  Created by Cursor on 2026/3/30.
//

#import "YALTimelineManager.h"
#import "YALNetworkManager.h"
#import "YALAuthManager.h"
#import "YALContentManager.h"

static NSString * const kYALAPIBaseURL = @"http://8.137.158.7:9000/api";

@implementation YALTimelineManager

+ (instancetype)sharedManager {
    static YALTimelineManager *mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[YALTimelineManager alloc] init];
    });
    return mgr;
}

static NSDictionary *YALExtractDataDict(id responseObject) {
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dic = (NSDictionary *)responseObject;
    // 兼容 {code,msg,data} 与 “直接返回 data 字典” 两种形态
    id codeObj = dic[@"code"];
    if (codeObj) {
        id data = dic[@"data"];
        return [data isKindOfClass:[NSDictionary class]] ? (NSDictionary *)data : nil;
    }
    return dic;
}

static NSString *YALExtractMsg(id responseObject) {
    if (![responseObject isKindOfClass:[NSDictionary class]]) return nil;
    id msg = ((NSDictionary *)responseObject)[@"msg"];
    return [msg isKindOfClass:[NSString class]] ? (NSString *)msg : nil;
}

static NSInteger YALExtractCode(id responseObject) {
    if (![responseObject isKindOfClass:[NSDictionary class]]) return -1;
    id codeObj = ((NSDictionary *)responseObject)[@"code"];
    return [codeObj respondsToSelector:@selector(integerValue)] ? [codeObj integerValue] : 200;
}

- (void)fetchMyTimelineWithYear:(nullable NSNumber *)year
                     completion:(void (^)(BOOL success,
                                          NSDictionary<NSString *,NSArray *> * _Nullable groupedByYearMonth,
                                          NSString * _Nullable message,
                                          NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/timeline/my", kYALAPIBaseURL];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSLog(@"日期：%@", params[@"year"]);
    if (year && [year respondsToSelector:@selector(integerValue)] && year.integerValue > 0) {
        params[@"year"] = @([year integerValue]);
    }
    NSDictionary *headers = [[YALAuthManager sharedManager] authHeadersForLoginRequiredRequest];
    NSLog(@"几个呢：%d", params.count);
    [network GET:url parameters:(params.count > 0 ? params : nil) headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSInteger code = YALExtractCode(responseObject);
        NSString *msg = YALExtractMsg(responseObject);
        NSDictionary *dataDict = YALExtractDataDict(responseObject);

        if (code != 200) {
            NSString *m = msg.length > 0 ? msg : @"请求失败";
            NSError *e = [NSError errorWithDomain:@"YALTimelineManager" code:code userInfo:@{NSLocalizedDescriptionKey: m}];
            if (completion) completion(NO, nil, m, e);
            return;
        }
        if (![dataDict isKindOfClass:[NSDictionary class]]) {
            NSError *e = [NSError errorWithDomain:@"YALTimelineManager" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"返回数据格式错误"}];
            if (completion) completion(NO, nil, @"返回数据格式错误", e);
            return;
        }

        NSMutableDictionary<NSString *, NSArray *> *normalized = [NSMutableDictionary dictionary];
        [dataDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            (void)stop;
            if (![key isKindOfClass:[NSString class]]) return;
            if ([obj isKindOfClass:[NSArray class]]) {
                normalized[(NSString *)key] = (NSArray *)obj;
            }
        }];

        if (completion) completion(YES, [normalized copy], msg, nil);
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) completion(NO, nil, error.localizedDescription, error);
    }];
}

- (void)filterContentWithCity:(nullable NSString *)city
                         year:(nullable NSString *)year
                         mood:(nullable NSString *)mood
                   completion:(void (^)(BOOL success, NSArray * _Nullable list, NSString * _Nullable message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/filter", kYALAPIBaseURL];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (city.length > 0) params[@"city"] = city;
    if (year.length > 0) params[@"year"] = year;
    if (mood.length > 0) params[@"mood"] = mood;

    NSDictionary *headers = [[YALAuthManager sharedManager] authHeadersForLoginRequiredRequest];
    [network GET:url parameters:(params.count > 0 ? params : nil) headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSInteger code = YALExtractCode(responseObject);
        NSString *msg = YALExtractMsg(responseObject);
        id data = nil;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = (NSDictionary *)responseObject;
            if (dic[@"code"]) {
                data = dic[@"data"];
            } else {
                data = responseObject;
            }
        }
        if (code != 200) {
            NSString *m = msg.length > 0 ? msg : @"请求失败";
            NSError *e = [NSError errorWithDomain:@"YALTimelineManager" code:code userInfo:@{NSLocalizedDescriptionKey: m}];
            if (completion) completion(NO, nil, m, e);
            return;
        }
        if (![data isKindOfClass:[NSArray class]]) {
            // 有些后端会返回 {list:[]}
            if ([data isKindOfClass:[NSDictionary class]] && [((NSDictionary *)data)[@"list"] isKindOfClass:[NSArray class]]) {
                if (completion) completion(YES, ((NSDictionary *)data)[@"list"], msg, nil);
                return;
            }
            NSError *e = [NSError errorWithDomain:@"YALTimelineManager" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"返回数据格式错误"}];
            if (completion) completion(NO, nil, @"返回数据格式错误", e);
            return;
        }
        if (completion) completion(YES, (NSArray *)data, msg, nil);
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) completion(NO, nil, error.localizedDescription, error);
    }];
}

- (void)fetchMyContentListWithCompletion:(void (^)(BOOL success, NSArray * _Nullable list, NSString * _Nullable message, NSError * _Nullable error))completion {
    // 直接复用 content manager 的 /content/my 能力，拉一页大数据供 Memory/Timeline 本地筛选
    [[YALContentManager sharedManager] getMyContentListWithPage:1
                                                        pageSize:1000
                                                      completion:^(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error) {
        if (completion) {
            completion(success, contentList, message, error);
        }
    }];
}

@end

