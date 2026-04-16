//
//  YALContentManager.m
//  MemoryCity
//
//  Created by mac on 2026/3/29.
//

#import "YALContentManager.h"
#import "YALNetworkManager.h"
#import "YALAuthManager.h"
#import "YALPostModel.h"
#import "YALSearchContentModel.h"
#import "YALSearchUserModel.h"
#import "YALAIAnalyzeResultModel.h"
#import "YALPostCacheStore.h"

static NSNumber *YALResolvedUserId(void) {
    YALAuthUserModel *currentUser = [[YALAuthManager sharedManager] currentUser];
    if (currentUser.userId > 0) {
        return @(currentUser.userId);
    }
    return @(1);
}

static NSInteger YALResponseCode(id responseObject) {
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        return -1;
    }
    id codeObj = ((NSDictionary *)responseObject)[@"code"];
    return [codeObj respondsToSelector:@selector(integerValue)] ? [codeObj integerValue] : 200;
}

static NSString *YALResponseMessage(id responseObject) {
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    id msg = ((NSDictionary *)responseObject)[@"msg"];
    return [msg isKindOfClass:[NSString class]] ? (NSString *)msg : @"";
}

static NSDictionary *YALResponseData(id responseObject) {
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id data = ((NSDictionary *)responseObject)[@"data"];
    if ([data isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)data;
    }
    return [responseObject isKindOfClass:[NSDictionary class]] ? (NSDictionary *)responseObject : nil;
}

static NSArray *YALSearchListFromResponse(id responseObject, id data, NSArray<NSString *> *preferredKeys) {
    if ([responseObject isKindOfClass:[NSArray class]]) {
        return (NSArray *)responseObject;
    }
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        id rawData = ((NSDictionary *)responseObject)[@"data"];
        if ([rawData isKindOfClass:[NSArray class]]) {
            return (NSArray *)rawData;
        }
    }
    if ([data isKindOfClass:[NSArray class]]) {
        return (NSArray *)data;
    }
    if (![data isKindOfClass:[NSDictionary class]]) {
        return @[];
    }
    NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithArray:preferredKeys ?: @[]];
    [keys addObjectsFromArray:@[@"list", @"records", @"items", @"results", @"data"]];
    for (NSString *key in keys) {
        id value = data[key];
        if ([value isKindOfClass:[NSArray class]]) {
            return (NSArray *)value;
        }
    }
    return @[];
}

static NSArray *YALFlattenSearchWrappedList(NSArray *rawList, NSArray<NSString *> *nestedKeys) {
    if (![rawList isKindOfClass:[NSArray class]]) {
        return @[];
    }

    NSMutableArray *flattened = [NSMutableArray array];
    for (id item in rawList) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            [flattened addObject:item];
            continue;
        }

        NSDictionary *dict = (NSDictionary *)item;
        BOOL didAppendNestedList = NO;
        for (NSString *key in nestedKeys) {
            id nestedValue = dict[key];
            if ([nestedValue isKindOfClass:[NSArray class]]) {
                [flattened addObjectsFromArray:(NSArray *)nestedValue];
                didAppendNestedList = YES;
                break;
            }
        }

        if (!didAppendNestedList) {
            [flattened addObject:item];
        }
    }
    return [flattened copy];
}

static BOOL YALContentListBoolValue(id value, BOOL fallback) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [((NSNumber *)value) integerValue] != 0;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [((NSString *)value) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) {
            return fallback;
        }
        NSString *lower = text.lowercaseString;
        if ([lower isEqualToString:@"1"] ||
            [lower isEqualToString:@"true"] ||
            [lower isEqualToString:@"yes"] ||
            [lower isEqualToString:@"public"] ||
            [lower isEqualToString:@"公开"]) {
            return YES;
        }
        if ([lower isEqualToString:@"0"] ||
            [lower isEqualToString:@"false"] ||
            [lower isEqualToString:@"no"] ||
            [lower isEqualToString:@"private"] ||
            [lower isEqualToString:@"私密"] ||
            [lower isEqualToString:@"仅自己可见"]) {
            return NO;
        }
    }
    return fallback;
}

static BOOL YALContentListShouldShowPublicContent(NSDictionary *dict) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    NSArray<NSString *> *publicKeys = @[@"is_public", @"isPublic", @"visible", @"visibility", @"public_status"];
    for (NSString *key in publicKeys) {
        id value = dict[key];
        if (!value || value == [NSNull null]) {
            continue;
        }
        return YALContentListBoolValue(value, NO);
    }

    // 公开流里拿不到明确公开标记时，按不展示处理。
    return NO;
}

static BOOL YALIsValidSearchContentModel(YALSearchContentModel *model) {
    if (![model isKindOfClass:[YALSearchContentModel class]]) {
        return NO;
    }

    BOOL hasIdentity = [model.contentId respondsToSelector:@selector(integerValue)] && model.contentId.integerValue > 0;
    BOOL hasTitle = model.title.length > 0;
    BOOL hasContent = model.content.length > 0;
    BOOL hasImages = model.images.count > 0;
    BOOL hasMeta = model.city.length > 0 || model.year.length > 0 || model.mood.length > 0;
    BOOL hasAuthor = model.authorNickname.length > 0 || model.authorUsername.length > 0;

    return hasIdentity && (hasTitle || hasContent || hasImages || hasMeta || hasAuthor);
}

static BOOL YALIsFormatError(id responseObject) {
    NSString *msg = YALResponseMessage(responseObject);
    return (YALResponseCode(responseObject) == 400 &&
            [msg containsString:@"参数"] &&
            [msg containsString:@"格式"]);
}

static BOOL YALShouldRetryAlternatePayload(id responseObject) {
    NSString *msg = YALResponseMessage(responseObject);
    if (YALIsFormatError(responseObject)) {
        return YES;
    }
    if ([msg containsString:@"内容ID不能为空"]) {
        return YES;
    }
    if ([msg containsString:@"fk_comments_replies"]) {
        return YES;
    }
    return NO;
}

static NSNumber *YALNumberFromLikeFlag(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length > 0) {
            return @([text integerValue]);
        }
    }
    return nil;
}

static NSString *YALAIStreamTrimmedString(id value) {
    if (![value isKindOfClass:[NSString class]]) {
        return @"";
    }
    return [((NSString *)value) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static id YALAIJSONObjectFromString(NSString *text) {
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length == 0) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

static NSArray<NSString *> *YALAIStreamStringArray(id value) {
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    if ([value isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)value) {
            NSString *text = YALAIStreamTrimmedString(item);
            if (text.length > 0) {
                [items addObject:text];
            }
        }
        return [items copy];
    }

    NSString *text = YALAIStreamTrimmedString(value);
    if (text.length == 0) {
        return @[];
    }
    NSArray<NSString *> *components = [text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",，\n"]];
    for (NSString *component in components) {
        NSString *trimmed = YALAIStreamTrimmedString(component);
        if (trimmed.length > 0) {
            [items addObject:trimmed];
        }
    }
    return [items copy];
}

static void YALAIAppendUniqueStrings(NSMutableArray<NSString *> *target, NSArray<NSString *> *values) {
    for (NSString *value in values) {
        if (value.length == 0 || [target containsObject:value]) {
            continue;
        }
        [target addObject:value];
    }
}

static BOOL YALAIApplyStreamPayloadToModel(YALAIAnalyzeResultModel *model, NSDictionary *payload) {
    if (![payload isKindOfClass:[NSDictionary class]] || model == nil) {
        return NO;
    }

    NSDictionary *nestedPayload = nil;
    if ([payload[@"data"] isKindOfClass:[NSDictionary class]]) {
        nestedPayload = payload[@"data"];
    } else if ([payload[@"result"] isKindOfClass:[NSDictionary class]]) {
        nestedPayload = payload[@"result"];
    }
    if (nestedPayload != nil && nestedPayload != payload) {
        return YALAIApplyStreamPayloadToModel(model, nestedPayload);
    }

    BOOL didUpdate = NO;
    NSString *summary = YALAIStreamTrimmedString(payload[@"summary"]);
    if (summary.length > 0) {
        model.summary = summary;
        didUpdate = YES;
    }

    NSString *suggestions = YALAIStreamTrimmedString(payload[@"suggestions"]);
    if (suggestions.length > 0) {
        model.suggestions = suggestions;
        didUpdate = YES;
    }

    NSString *guide = YALAIStreamTrimmedString(payload[@"guide"]);
    if (guide.length > 0) {
        model.guide = guide;
        didUpdate = YES;
    }

    NSString *mood = YALAIStreamTrimmedString(payload[@"mood"]);
    if (mood.length > 0) {
        model.mood = mood;
        didUpdate = YES;
    }

    NSArray<NSString *> *tags = YALAIStreamStringArray(payload[@"tags"]);
    if (tags.count > 0) {
        model.tags = tags;
        didUpdate = YES;
    }

    NSArray<NSString *> *highlights = YALAIStreamStringArray(payload[@"highlights"]);
    if (highlights.count > 0) {
        model.highlights = highlights;
        didUpdate = YES;
    }

    NSString *summaryDelta = YALAIStreamTrimmedString(payload[@"summary_delta"]);
    if (summaryDelta.length > 0) {
        NSString *currentSummary = model.summary ?: @"";
        model.summary = currentSummary.length > 0 ? [currentSummary stringByAppendingString:summaryDelta] : summaryDelta;
        didUpdate = YES;
    }

    NSString *suggestionsDelta = YALAIStreamTrimmedString(payload[@"suggestions_delta"]);
    if (suggestionsDelta.length > 0) {
        NSString *currentSuggestions = model.suggestions ?: @"";
        model.suggestions = currentSuggestions.length > 0 ? [currentSuggestions stringByAppendingString:suggestionsDelta] : suggestionsDelta;
        didUpdate = YES;
    }

    NSString *guideDelta = YALAIStreamTrimmedString(payload[@"guide_delta"]);
    if (guideDelta.length > 0) {
        NSString *currentGuide = model.guide ?: @"";
        model.guide = currentGuide.length > 0 ? [currentGuide stringByAppendingString:guideDelta] : guideDelta;
        didUpdate = YES;
    }

    NSString *moodDelta = YALAIStreamTrimmedString(payload[@"mood_delta"]);
    if (moodDelta.length > 0) {
        NSString *currentMood = model.mood ?: @"";
        model.mood = currentMood.length > 0 ? [currentMood stringByAppendingString:moodDelta] : moodDelta;
        didUpdate = YES;
    }

    NSArray<NSString *> *tagsDelta = YALAIStreamStringArray(payload[@"tags_delta"]);
    if (tagsDelta.count > 0) {
        NSMutableArray<NSString *> *mergedTags = [NSMutableArray arrayWithArray:model.tags ?: @[]];
        YALAIAppendUniqueStrings(mergedTags, tagsDelta);
        model.tags = [mergedTags copy];
        didUpdate = YES;
    }

    NSArray<NSString *> *highlightsDelta = YALAIStreamStringArray(payload[@"highlights_delta"]);
    if (highlightsDelta.count > 0) {
        NSMutableArray<NSString *> *mergedHighlights = [NSMutableArray arrayWithArray:model.highlights ?: @[]];
        YALAIAppendUniqueStrings(mergedHighlights, highlightsDelta);
        model.highlights = [mergedHighlights copy];
        didUpdate = YES;
    }

    NSString *field = YALAIStreamTrimmedString(payload[@"field"]);
    if (field.length == 0) {
        field = YALAIStreamTrimmedString(payload[@"type"]);
    }
    if (field.length == 0) {
        field = YALAIStreamTrimmedString(payload[@"target"]);
    }
    NSString *deltaText = YALAIStreamTrimmedString(payload[@"delta"]);
    if (deltaText.length == 0) {
        deltaText = YALAIStreamTrimmedString(payload[@"content"]);
    }
    if (deltaText.length == 0) {
        deltaText = YALAIStreamTrimmedString(payload[@"text"]);
    }

    if (field.length > 0 && deltaText.length > 0) {
        if ([field isEqualToString:@"summary"]) {
            NSString *currentSummary = model.summary ?: @"";
            model.summary = currentSummary.length > 0 ? [currentSummary stringByAppendingString:deltaText] : deltaText;
            didUpdate = YES;
        } else if ([field isEqualToString:@"suggestions"]) {
            NSString *currentSuggestions = model.suggestions ?: @"";
            model.suggestions = currentSuggestions.length > 0 ? [currentSuggestions stringByAppendingString:deltaText] : deltaText;
            didUpdate = YES;
        } else if ([field isEqualToString:@"guide"]) {
            NSString *currentGuide = model.guide ?: @"";
            model.guide = currentGuide.length > 0 ? [currentGuide stringByAppendingString:deltaText] : deltaText;
            didUpdate = YES;
        } else if ([field isEqualToString:@"mood"]) {
            NSString *currentMood = model.mood ?: @"";
            model.mood = currentMood.length > 0 ? [currentMood stringByAppendingString:deltaText] : deltaText;
            didUpdate = YES;
        } else if ([field isEqualToString:@"highlights"]) {
            NSMutableArray<NSString *> *mergedHighlights = [NSMutableArray arrayWithArray:model.highlights ?: @[]];
            YALAIAppendUniqueStrings(mergedHighlights, YALAIStreamStringArray(deltaText));
            model.highlights = [mergedHighlights copy];
            didUpdate = YES;
        } else if ([field isEqualToString:@"tags"]) {
            NSMutableArray<NSString *> *mergedTags = [NSMutableArray arrayWithArray:model.tags ?: @[]];
            YALAIAppendUniqueStrings(mergedTags, YALAIStreamStringArray(deltaText));
            model.tags = [mergedTags copy];
            didUpdate = YES;
        } else if (![field isEqualToString:@"start"] &&
                   ![field isEqualToString:@"done"] &&
                   ![field isEqualToString:@"end"] &&
                   ![field isEqualToString:@"finish"]) {
            NSString *currentSummary = model.summary ?: @"";
            model.summary = currentSummary.length > 0 ? [currentSummary stringByAppendingString:deltaText] : deltaText;
            didUpdate = YES;
        }
    }

    if (!didUpdate) {
        NSString *contentText = YALAIStreamTrimmedString(payload[@"content"]);
        NSString *typeText = YALAIStreamTrimmedString(payload[@"type"]).lowercaseString;
        if (contentText.length > 0 &&
            ![typeText isEqualToString:@"start"] &&
            ![typeText isEqualToString:@"done"] &&
            ![typeText isEqualToString:@"end"] &&
            ![typeText isEqualToString:@"finish"]) {
            NSString *currentSummary = model.summary ?: @"";
            model.summary = currentSummary.length > 0 ? [currentSummary stringByAppendingString:contentText] : contentText;
            didUpdate = YES;
        }
    }

    return didUpdate;
}

@implementation YALContentManager

+ (instancetype)sharedManager {
    static YALContentManager *contentManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        contentManager = [[YALContentManager alloc] init];
    });
    return contentManager;
}

- (void)publishContentWithTitle:(NSString *)title
                        content:(NSString *)content
                           city:(NSString *)city
                           year:(NSString *)year
                           mood:(NSString *)mood
                         images:(NSArray<NSString *> *)images
                   locationName:(nullable NSString *)locationName
                       latitude:(double)latitude
                      longitude:(double)longitude
                       isPublic:(BOOL)isPublic
                         userId:(nullable NSNumber *)userId
                     completion:(void (^)(BOOL success, NSString *message, NSNumber * _Nullable contentId, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/publish", YALAPIBaseURLString];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"title"] = title;
    parameters[@"content"] = content;
    parameters[@"city"] = city;
    // year 参数用于后端解析发布时间（你的 UI 里用的是 yyyy.MM.dd）
    // 这里不再截取数字，以便后端能拿到月份/日期并正确落库用于 /timeline/my 分组
    parameters[@"year"] = (year.length > 0 ? year : @"");
    parameters[@"mood"] = mood;
    // 处理图片上传
    if (images && [images isKindOfClass:[NSArray class]] && images.count > 0) {
        // 后端可能把传入字符串当“URL去拉取”，如果你传的是 base64（如 /9j/4AAQ...）会触发错误：
        //   Get "/9j/4AAQ..."
        // 因此把“看起来像 base64”的字符串补成 data URL，通常后端会据此走 base64 解码分支。
        NSMutableArray<NSString *> *fixedImages = [NSMutableArray array];
        for (id obj in images) {
            if (![obj isKindOfClass:[NSString class]]) continue;
            NSString *imgStr = (NSString *)obj;
            if (imgStr.length == 0) continue;
            if ([imgStr hasPrefix:@"data:image/"]) {
                [fixedImages addObject:imgStr];
            } else if ([imgStr hasPrefix:@"http://"] || [imgStr hasPrefix:@"https://"]) {
                // 如果本来就是 URL，保持不变
                [fixedImages addObject:imgStr];
            } else if ([imgStr containsString:@"base64"]) {
                // 如果已经包含 base64 标记但不是 data URL，就尝试补齐（尽量按 jpeg 处理）
                if ([imgStr containsString:@","]) {
                    // e.g. base64,... 这种形态
                    [fixedImages addObject:imgStr];
                } else {
                    [fixedImages addObject:[NSString stringWithFormat:@"data:image/jpeg;base64,%@", imgStr]];
                }
            } else {
                // 兜底：当作 base64 纯串处理
                [fixedImages addObject:[NSString stringWithFormat:@"data:image/jpeg;base64,%@", imgStr]];
            }
        }
        parameters[@"images"] = fixedImages;

        // 如果是Base64图片，记录大小
        if (fixedImages.count > 0 && [fixedImages.firstObject isKindOfClass:[NSString class]]) {
            NSString *firstImage = fixedImages.firstObject;
            (void)firstImage;
        }
    } else {
        parameters[@"images"] = @[];
    }
    parameters[@"latitude"] = @(latitude);
    parameters[@"longitude"] = @(longitude);
    // Go 后端的 is_public 是 bool，主字段必须传 true/false。
    NSNumber *publicBoolValue = @(isPublic);
    NSNumber *privateBoolValue = @(!isPublic);
    NSNumber *publicStatusValue = @(isPublic ? 1 : 0);
    parameters[@"is_public"] = publicBoolValue;
    parameters[@"isPublic"] = publicBoolValue;
    parameters[@"visible"] = publicBoolValue;
    parameters[@"public_status"] = publicStatusValue;
    parameters[@"is_private"] = privateBoolValue;
    parameters[@"private"] = privateBoolValue;

    if (locationName) {
        parameters[@"location_name"] = locationName;
    }

    NSNumber *finalUserId = nil;

    if (userId) {
        if ([userId isKindOfClass:[NSNumber class]]) {
            finalUserId = userId;
        } else if ([userId isKindOfClass:[NSString class]]) {
            NSInteger uid = [(NSString *)userId integerValue];
            if (uid > 0) {
                finalUserId = @(uid);
            }
        }
    }

    // 如果解析失败，尝试从当前登录用户获取userId
    if (!finalUserId) {
        YALAuthUserModel *currentUser = [[YALAuthManager sharedManager] currentUser];
        if (currentUser && currentUser.userId > 0) {
            finalUserId = @(currentUser.userId);
        } else {
            // 如果没有登录用户，使用默认值1
            finalUserId = @(1);
        }
    }

    // 确保user_id是NSNumber类型且值大于0
    if (![finalUserId isKindOfClass:[NSNumber class]] || [finalUserId integerValue] <= 0) {
        finalUserId = @(1);
    }

    parameters[@"user_id"] = finalUserId;

    // 获取认证headers
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network POST:url
       parameters:parameters
          headers:headers
         progress:nil
          success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
            NSDictionary *data = [response[@"data"] isKindOfClass:[NSDictionary class]] ? response[@"data"] : nil;

            if (code == 200) {
                NSNumber *contentId = data[@"content_id"];
                if (completion) {
                    completion(YES, msg, contentId, nil);
                }
            } else {
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                         code:code
                                                     userInfo:@{NSLocalizedDescriptionKey: msg}];
                    completion(NO, msg, nil, error);
                }
            }
        } else {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                     code:-1
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}];
                completion(NO, @"无效的响应", nil, error);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, @"网络请求失败", nil, error);
        }
    }];
}

- (void)getContentDetailWithId:(NSNumber *)contentId
                    completion:(void (^)(BOOL success, NSDictionary * _Nullable content, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/detail", YALAPIBaseURLString];

    NSDictionary *parameters = @{@"content_id": contentId};

    // 获取认证headers
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network GET:url
      parameters:parameters
         headers:headers
        progress:nil
         success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
            NSDictionary *data = [response[@"data"] isKindOfClass:[NSDictionary class]] ? response[@"data"] : nil;

            if (code == 200) {
                if (data && contentId.integerValue > 0) {
                    [[YALPostCacheStore sharedStore] cacheContentDetail:data contentId:contentId completion:^(NSError * _Nullable error) {
                        (void)error;
                    }];
                }
                if (completion) {
                    completion(YES, data, nil);
                }
            } else {
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                         code:code
                                                     userInfo:@{NSLocalizedDescriptionKey: msg}];
                    completion(NO, nil, error);
                }
            }
        } else {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                     code:-1
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}];
                completion(NO, nil, error);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, nil, error);
        }
    }];
}

- (void)searchContentWithKeyword:(NSString *)keyword
                            page:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                      completion:(void (^)(BOOL success, NSArray<YALSearchContentModel *> * _Nullable contentList, NSInteger total, NSString * _Nullable message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/search", YALAPIBaseURLString];

    NSDictionary *parameters = @{
        @"keyword": keyword ?: @"",
        @"search_type": @"content",
        @"page": @(MAX(page, 1)),
        @"size": @(MAX(pageSize, 1))
    };
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network GET:url parameters:parameters headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSInteger code = YALResponseCode(responseObject);
        NSString *msg = YALResponseMessage(responseObject);
        NSDictionary *data = YALResponseData(responseObject);

        if (code != 200) {
            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:code
                                             userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"搜索失败"}];
            if (completion) {
                completion(NO, nil, 0, msg, error);
            }
            return;
        }

        NSArray *rawList = YALSearchListFromResponse(responseObject, data, @[@"contents", @"content_list"]);
        NSMutableArray<YALSearchContentModel *> *models = [NSMutableArray arrayWithCapacity:rawList.count];
        for (id item in rawList) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            YALSearchContentModel *model = [[YALSearchContentModel alloc] initWithDictionary:item];
            if (YALIsValidSearchContentModel(model)) {
                [models addObject:model];
            }
        }

        NSInteger total = 0;
        id totalValue = data[@"total"];
        if ([totalValue respondsToSelector:@selector(integerValue)]) {
            total = MAX([totalValue integerValue], 0);
        } else {
            total = models.count;
        }

        if (completion) {
            completion(YES, [models copy], total, msg, nil);
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, nil, 0, @"网络请求失败", error);
        }
    }];
}

- (void)searchUsersWithKeyword:(NSString *)keyword
                          page:(NSInteger)page
                      pageSize:(NSInteger)pageSize
                    completion:(void (^)(BOOL success, NSArray<YALSearchUserModel *> * _Nullable userList, NSInteger total, NSString * _Nullable message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/search", YALAPIBaseURLString];

    NSDictionary *parameters = @{
        @"keyword": keyword ?: @"",
        @"search_type": @"user",
        @"page": @(MAX(page, 1)),
        @"size": @(MAX(pageSize, 1))
    };
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network GET:url parameters:parameters headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSInteger code = YALResponseCode(responseObject);
        NSString *msg = YALResponseMessage(responseObject);
        NSDictionary *data = YALResponseData(responseObject);

        if (code != 200) {
            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:code
                                             userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"搜索失败"}];
            if (completion) {
                completion(NO, nil, 0, msg, error);
            }
            return;
        }

        NSArray *rawList = YALSearchListFromResponse(responseObject, data, @[@"users", @"user_list", @"userList"]);
        rawList = YALFlattenSearchWrappedList(rawList, @[@"user", @"users", @"user_list", @"list"]);
        NSMutableArray<YALSearchUserModel *> *models = [NSMutableArray arrayWithCapacity:rawList.count];
        for (id item in rawList) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            [models addObject:[[YALSearchUserModel alloc] initWithDictionary:item]];
        }

        NSInteger total = 0;
        id totalValue = data[@"total"];
        if ([totalValue respondsToSelector:@selector(integerValue)]) {
            total = MAX([totalValue integerValue], 0);
        } else {
            total = models.count;
        }

        if (completion) {
            completion(YES, [models copy], total, msg, nil);
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, nil, 0, @"网络请求失败", error);
        }
    }];
}

- (void)searchAllWithKeyword:(NSString *)keyword
                        page:(NSInteger)page
                    pageSize:(NSInteger)pageSize
                  completion:(void (^)(BOOL success,
                                       NSArray<YALSearchContentModel *> * _Nullable contentList,
                                       NSArray<YALSearchUserModel *> * _Nullable userList,
                                       NSString * _Nullable message,
                                       NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/search", YALAPIBaseURLString];

    NSDictionary *parameters = @{
        @"keyword": keyword ?: @"",
        @"page": @(MAX(page, 1)),
        @"size": @(MAX(pageSize, 1))
    };
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network GET:url parameters:parameters headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSInteger code = YALResponseCode(responseObject);
        NSString *msg = YALResponseMessage(responseObject);
        NSDictionary *data = YALResponseData(responseObject);

        if (code != 200) {
            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:code
                                             userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"搜索失败"}];
            if (completion) {
                completion(NO, nil, nil, msg, error);
            }
            return;
        }

        NSArray *rawContentList = YALSearchListFromResponse(responseObject, data, @[@"content_list", @"contentList", @"contents"]);
        rawContentList = YALFlattenSearchWrappedList(rawContentList, @[@"content", @"contents", @"content_list", @"list"]);
        NSMutableArray<YALSearchContentModel *> *contentModels = [NSMutableArray arrayWithCapacity:rawContentList.count];
        for (id item in rawContentList) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            YALSearchContentModel *model = [[YALSearchContentModel alloc] initWithDictionary:item];
            if (YALIsValidSearchContentModel(model)) {
                [contentModels addObject:model];
            }
        }

        NSArray *rawUserList = YALSearchListFromResponse(responseObject, data, @[@"user_list", @"userList", @"users"]);
        rawUserList = YALFlattenSearchWrappedList(rawUserList, @[@"user", @"users", @"user_list", @"list"]);
        NSMutableArray<YALSearchUserModel *> *userModels = [NSMutableArray arrayWithCapacity:rawUserList.count];
        for (id item in rawUserList) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            [userModels addObject:[[YALSearchUserModel alloc] initWithDictionary:item]];
        }
        if (completion) {
            completion(YES, [contentModels copy], [userModels copy], msg, nil);
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, nil, nil, @"网络请求失败", error);
        }
    }];
}

- (void)analyzeText:(NSString *)text
         completion:(void (^)(BOOL success, YALAIAnalyzeResultModel * _Nullable result, NSString * _Nullable message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/ai/analyze", YALAPIBaseURLString];
    NSDictionary *parameters = @{@"text": text ?: @""};
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network POST:url parameters:parameters headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSDictionary *payload = nil;
        NSString *msg = @"success";
        NSInteger code = 200;

        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            if ([response[@"summary"] isKindOfClass:[NSString class]] ||
                [response[@"tags"] isKindOfClass:[NSArray class]] ||
                [response[@"mood"] isKindOfClass:[NSString class]] ||
                [response[@"suggestions"] isKindOfClass:[NSString class]] ||
                [response[@"highlights"] isKindOfClass:[NSArray class]] ||
                [response[@"guide"] isKindOfClass:[NSString class]]) {
                payload = response;
            } else {
                code = YALResponseCode(responseObject);
                msg = YALResponseMessage(responseObject);
                NSDictionary *data = YALResponseData(responseObject);
                if ([data isKindOfClass:[NSDictionary class]]) {
                    payload = data;
                }
            }
        }

        if (code != 200 || ![payload isKindOfClass:[NSDictionary class]]) {
            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:(code == 200 ? -1 : code)
                                             userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"AI 分析失败"}];
            if (completion) {
                completion(NO, nil, msg, error);
            }
            return;
        }

        YALAIAnalyzeResultModel *model = [[YALAIAnalyzeResultModel alloc] initWithDictionary:payload];
        if (completion) {
            completion(YES, model, msg, nil);
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, nil, @"网络请求失败", error);
        }
    }];
}

- (NSURLSessionDataTask *)analyzeText:(NSString *)text
                             onUpdate:(void (^ _Nullable)(YALAIAnalyzeResultModel *result))onUpdate
                           completion:(void (^)(BOOL success, YALAIAnalyzeResultModel * _Nullable result, NSString * _Nullable message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/ai/analyze", YALAPIBaseURLString];
    NSDictionary *parameters = @{@"text": text ?: @""};
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:[[YALAuthManager sharedManager] getAuthHeadersWithToken] ?: @{}];
    headers[@"Accept"] = @"text/event-stream, application/json";
    headers[@"Cache-Control"] = @"no-cache";

    __block NSMutableString *buffer = [NSMutableString string];
    __block NSMutableArray<NSString *> *eventLines = [NSMutableArray array];
    __block NSMutableData *fullResponseData = [NSMutableData data];
    __block YALAIAnalyzeResultModel *streamModel = [[YALAIAnalyzeResultModel alloc] initWithDictionary:@{}];
    __block BOOL didEmitUpdate = NO;

    void (^emitPlainText)(NSString *) = ^(NSString *rawText) {
        NSString *textChunk = rawText ?: @"";
        if (textChunk.length == 0) {
            return;
        }
        NSString *currentSummary = streamModel.summary ?: @"";
        streamModel.summary = currentSummary.length > 0 ? [currentSummary stringByAppendingString:textChunk] : textChunk;
        didEmitUpdate = YES;
        if (onUpdate) {
            onUpdate(streamModel);
        }
    };

    void (^emitPayloadString)(NSString *) = ^(NSString *rawString) {
        NSString *trimmed = [rawString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0 || [trimmed isEqualToString:@"[DONE]"]) {
            return;
        }

        id jsonObject = YALAIJSONObjectFromString(trimmed);
        if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            if (YALAIApplyStreamPayloadToModel(streamModel, (NSDictionary *)jsonObject)) {
                didEmitUpdate = YES;
                if (onUpdate) {
                    onUpdate(streamModel);
                }
            }
            return;
        }

        emitPlainText(rawString);
    };

    void (^flushBufferedLines)(void) = ^{
        if (eventLines.count == 0) {
            return;
        }
        NSString *eventPayload = [eventLines componentsJoinedByString:@"\n"];
        [eventLines removeAllObjects];
        emitPayloadString(eventPayload);
    };

    NSURLSessionDataTask *task = [network streamPOST:url
                                          parameters:parameters
                                             headers:[headers copy]
                                     responseHandler:nil
                                         dataHandler:^(NSData * _Nonnull chunk) {
        if (chunk.length == 0) {
            return;
        }

        [fullResponseData appendData:chunk];
        NSString *chunkText = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        if (chunkText.length == 0) {
            return;
        }

        [buffer appendString:chunkText];
        NSRange newlineRange = [buffer rangeOfString:@"\n"];
        while (newlineRange.location != NSNotFound) {
            NSString *line = [buffer substringToIndex:newlineRange.location];
            [buffer deleteCharactersInRange:NSMakeRange(0, newlineRange.location + newlineRange.length)];
            NSString *cleanLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            if (cleanLine.length == 0) {
                flushBufferedLines();
            } else if ([cleanLine hasPrefix:@"data:"]) {
                NSString *payloadLine = [cleanLine substringFromIndex:5];
                if ([payloadLine hasPrefix:@" "]) {
                    payloadLine = [payloadLine substringFromIndex:1];
                }
                [eventLines addObject:payloadLine ?: @""];
            } else if ([cleanLine hasPrefix:@"event:"] || [cleanLine hasPrefix:@":"]) {
                // ignore SSE metadata/comment lines
            } else {
                flushBufferedLines();
                emitPayloadString(cleanLine);
            }
            newlineRange = [buffer rangeOfString:@"\n"];
        }
    } completion:^(NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        flushBufferedLines();
        if (buffer.length > 0) {
            emitPayloadString([buffer copy]);
            [buffer setString:@""];
        }

        if (error) {
            if (completion) {
                completion(NO, didEmitUpdate ? streamModel : nil, @"网络请求失败", error);
            }
            return;
        }

        NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? response.statusCode : 200;
        NSString *fullText = [[NSString alloc] initWithData:fullResponseData encoding:NSUTF8StringEncoding] ?: @"";
        NSString *message = @"success";

        if (statusCode < 200 || statusCode >= 300) {
            NSString *responseMessage = @"AI 分析失败";
            id object = YALAIJSONObjectFromString(fullText);
            if ([object isKindOfClass:[NSDictionary class]]) {
                responseMessage = YALResponseMessage(object);
                if (responseMessage.length == 0) {
                    responseMessage = @"AI 分析失败";
                }
            }
            NSError *statusError = [NSError errorWithDomain:@"YALContentManager"
                                                       code:statusCode
                                                   userInfo:@{NSLocalizedDescriptionKey: responseMessage}];
            if (completion) {
                completion(NO, didEmitUpdate ? streamModel : nil, responseMessage, statusError);
            }
            return;
        }

        if (!didEmitUpdate && fullText.length > 0) {
            id object = YALAIJSONObjectFromString(fullText);
            if ([object isKindOfClass:[NSDictionary class]]) {
                NSDictionary *responseObject = (NSDictionary *)object;
                if ([responseObject[@"summary"] isKindOfClass:[NSString class]] ||
                    [responseObject[@"tags"] isKindOfClass:[NSArray class]] ||
                    [responseObject[@"mood"] isKindOfClass:[NSString class]] ||
                    [responseObject[@"suggestions"] isKindOfClass:[NSString class]] ||
                    [responseObject[@"highlights"] isKindOfClass:[NSArray class]] ||
                    [responseObject[@"guide"] isKindOfClass:[NSString class]]) {
                    streamModel = [[YALAIAnalyzeResultModel alloc] initWithDictionary:responseObject];
                    didEmitUpdate = YES;
                } else {
                    NSInteger code = YALResponseCode(responseObject);
                    message = YALResponseMessage(responseObject);
                    NSDictionary *data = YALResponseData(responseObject);
                    if (code == 200 && [data isKindOfClass:[NSDictionary class]]) {
                        streamModel = [[YALAIAnalyzeResultModel alloc] initWithDictionary:data];
                        didEmitUpdate = YES;
                    }
                }
            } else if (fullText.length > 0 &&
                       [fullText rangeOfString:@"data:"].location == NSNotFound) {
                streamModel.summary = fullText;
                didEmitUpdate = YES;
            }
        }

        if (!didEmitUpdate) {
            NSError *parseError = [NSError errorWithDomain:@"YALContentManager"
                                                      code:-1
                                                  userInfo:@{NSLocalizedDescriptionKey: @"AI 分析失败"}];
            if (completion) {
                completion(NO, nil, @"AI 分析失败", parseError);
            }
            return;
        }

        if (completion) {
            completion(YES, streamModel, message, nil);
        }
    }];

    return task;
}

- (void)toggleLikeContentWithId:(NSNumber *)contentId
                     completion:(void (^)(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/interact/like", YALAPIBaseURLString];
    NSNumber *userId = YALResolvedUserId();

    NSArray<NSDictionary *> *parameterCandidates = @[
        @{@"content_id": contentId ?: @(0), @"user_id": userId},
        @{@"content_id": [NSString stringWithFormat:@"%@", contentId ?: @(0)],
          @"user_id": [NSString stringWithFormat:@"%@", userId]},
        @{@"contentId": contentId ?: @(0), @"userId": userId},
        @{@"content_id": contentId ?: @(0)}
    ];

    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];
    __block NSInteger candidateIndex = 0;
    __block void (^sendRequest)(void) = ^{
        NSDictionary *parameters = parameterCandidates[candidateIndex];
        [network POST:url parameters:parameters headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
            if (YALShouldRetryAlternatePayload(responseObject) && candidateIndex + 1 < parameterCandidates.count) {
                candidateIndex += 1;
                sendRequest();
                return;
            }

            NSInteger code = YALResponseCode(responseObject);
            NSDictionary *data = YALResponseData(responseObject);
            NSString *msg = YALResponseMessage(responseObject);
            if (code == 200) {
                if (completion) completion(YES, data, nil);
            } else {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"点赞失败"}];
                if (completion) completion(NO, nil, error);
            }
        } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
            if (completion) completion(NO, nil, error);
        }];
    };
    sendRequest();
}

- (void)getCommentListWithContentId:(NSNumber *)contentId
                               page:(NSInteger)page
                           pageSize:(NSInteger)pageSize
                         completion:(void (^)(BOOL success, NSArray * _Nullable comments, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/interact/comment/list", YALAPIBaseURLString];
    NSDictionary *parameters = @{
        @"content_id": contentId ?: @(0),
        @"page": @(MAX(page, 1)),
        @"size": @(MAX(pageSize, 1))
    };
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network GET:url parameters:parameters headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSArray *comments = nil;
        if ([responseObject isKindOfClass:[NSArray class]]) {
            comments = (NSArray *)responseObject;
        } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] respondsToSelector:@selector(integerValue)] ? [response[@"code"] integerValue] : 200;
            if (code != 200) {
                NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"评论获取失败";
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey: msg}];
                if (completion) completion(NO, nil, error);
                return;
            }

            id data = response[@"data"];
            if ([data isKindOfClass:[NSArray class]]) {
                comments = (NSArray *)data;
            } else if ([data isKindOfClass:[NSDictionary class]] && [data[@"list"] isKindOfClass:[NSArray class]]) {
                comments = data[@"list"];
            } else if ([response[@"list"] isKindOfClass:[NSArray class]]) {
                comments = response[@"list"];
            }
        }

        if (comments) {
            if (completion) completion(YES, comments, nil);
        } else {
            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:-2
                                             userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}];
            if (completion) completion(NO, nil, error);
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) completion(NO, nil, error);
    }];
}

- (void)publishCommentWithContentId:(NSNumber *)contentId
                            content:(NSString *)content
                           parentId:(NSNumber *)parentId
                         completion:(void (^)(BOOL success, NSDictionary * _Nullable comment, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSNumber *userId = YALResolvedUserId();
    NSString *url = [NSString stringWithFormat:@"%@/interact/comment", YALAPIBaseURLString];
    NSNumber *resolvedContentId = contentId ?: @(0);
    NSNumber *resolvedParentId = parentId ?: @(0);
    NSString *contentString = content ?: @"";
    NSString *parentIdString = (resolvedParentId.integerValue <= 0) ? @"" : [NSString stringWithFormat:@"%@", resolvedParentId];
    NSArray<NSDictionary *> *parameterCandidates = @[
        // 对齐后端当前结构体：
        // content_id: int64, content: string, parent_id: string（一级评论传空串）
        @{
            @"content_id": resolvedContentId,
            @"content": contentString,
            @"parent_id": parentIdString,
            @"user_id": userId
        },
        // 兜底1：有些实现会在一级评论场景要求不传 parent_id
        @{
            @"content_id": resolvedContentId,
            @"content": contentString,
            @"user_id": userId
        },
        // 兜底2：如果后端实际是全 string 绑定
        @{
            @"content_id": [NSString stringWithFormat:@"%@", resolvedContentId],
            @"content": contentString,
            @"parent_id": parentIdString,
            @"user_id": [NSString stringWithFormat:@"%@", userId]
        },
        // 驼峰版兜底
        @{
            @"contentId": resolvedContentId,
            @"content": contentString,
            @"parentId": resolvedParentId,
            @"userId": userId
        }
    ];
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    __block NSInteger candidateIndex = 0;
    __block void (^sendRequest)(void) = ^{
        NSDictionary *parameters = parameterCandidates[candidateIndex];
        [network POST:url parameters:parameters headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
            NSInteger code = YALResponseCode(responseObject);
            NSDictionary *data = YALResponseData(responseObject);
            NSString *msg = YALResponseMessage(responseObject);
            if (code == 200) {
                if (completion) completion(YES, data, nil);
                return;
            }

            // 参数问题或服务端内部异常时，自动尝试下一套参数，尽量保证联调可继续。
            if ((YALShouldRetryAlternatePayload(responseObject) || code == 500) &&
                candidateIndex + 1 < parameterCandidates.count) {
                candidateIndex += 1;
                sendRequest();
                return;
            }

            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:code
                                             userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"评论发布失败"}];
            if (completion) completion(NO, nil, error);
        } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
            if (candidateIndex + 1 < parameterCandidates.count) {
                candidateIndex += 1;
                sendRequest();
                return;
            }
            if (completion) completion(NO, nil, error);
        }];
    };
    sendRequest();
}

- (void)deleteCommentWithId:(NSNumber *)commentId
                 completion:(void (^)(BOOL success, NSString *message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSNumber *userId = YALResolvedUserId();
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];
    NSString *url = [NSString stringWithFormat:@"%@/interact/comment/delete", YALAPIBaseURLString];
    NSDictionary *parameters = @{
        @"comment_id": commentId ?: @(0),
        @"user_id": userId
    };
    [network DELETE:url
         parameters:parameters
            headers:headers
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSInteger code = YALResponseCode(responseObject);
        NSString *msg = YALResponseMessage(responseObject);
        if (code == 200) {
            if (completion) completion(YES, msg.length > 0 ? msg : @"删除成功", nil);
            return;
        }
        NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                             code:code
                                         userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"评论删除失败"}];
        if (completion) completion(NO, msg, error);
    } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion) completion(NO, error.localizedDescription ?: @"评论删除失败", error);
    }];
}

- (void)toggleCollectContentWithId:(NSNumber *)contentId
                        completion:(void (^)(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSNumber *userId = YALResolvedUserId();
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    NSString *contentIdString = [NSString stringWithFormat:@"%@", contentId ?: @(0)];
    NSString *userIdString = [NSString stringWithFormat:@"%@", userId ?: @(0)];
    NSArray<NSDictionary *> *requestCandidates = @[
        @{
            @"url": [NSString stringWithFormat:@"%@/interact/collect?content_id=%@&user_id=%@", YALAPIBaseURLString, contentIdString, userIdString],
            @"parameters": [NSNull null]
        },
        @{
            @"url": [NSString stringWithFormat:@"%@/interact/collect?content_id=%@", YALAPIBaseURLString, contentIdString],
            @"parameters": [NSNull null]
        },
        @{
            @"url": [NSString stringWithFormat:@"%@/interact/collect?contentId=%@&userId=%@", YALAPIBaseURLString, contentIdString, userIdString],
            @"parameters": [NSNull null]
        },
        @{
            @"url": [NSString stringWithFormat:@"%@/interact/collect?contentId=%@", YALAPIBaseURLString, contentIdString],
            @"parameters": [NSNull null]
        },
        @{
            @"url": [NSString stringWithFormat:@"%@/interact/collect", YALAPIBaseURLString],
            @"parameters": @{@"content_id": contentId ?: @(0), @"user_id": userId}
        }
    ];

    __block NSInteger candidateIndex = 0;
    __block void (^sendRequest)(void) = ^{
        NSDictionary *candidate = requestCandidates[candidateIndex];
        NSString *url = candidate[@"url"];
        id parametersObject = candidate[@"parameters"];
        NSDictionary *parameters = [parametersObject isKindOfClass:[NSDictionary class]] ? parametersObject : nil;
        [network POST:url parameters:parameters headers:headers progress:nil success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
            if (YALShouldRetryAlternatePayload(responseObject) && candidateIndex + 1 < requestCandidates.count) {
                candidateIndex += 1;
                sendRequest();
                return;
            }

            NSInteger code = YALResponseCode(responseObject);
            NSDictionary *data = YALResponseData(responseObject);
            NSString *msg = YALResponseMessage(responseObject);
            if (code == 200) {
                if (completion) completion(YES, data, nil);
            } else {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"收藏失败"}];
                if (completion) completion(NO, nil, error);
            }
        } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
            if (completion) completion(NO, nil, error);
        }];
    };
    sendRequest();
}

#pragma mark - 获取我的内容列表

- (void)getMyContentListWithPage:(NSInteger)page
                        pageSize:(NSInteger)pageSize
                      completion:(void (^)(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/my", YALAPIBaseURLString];

    // 构建请求参数
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"page"] = @(page);
    parameters[@"pageSize"] = @(pageSize);
    // 兼容后端常见分页参数命名（文档里是 size）
    parameters[@"size"] = @(pageSize);
    parameters[@"limit"] = @(pageSize);

    // 获取认证headers（需要token）
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network GET:url
      parameters:parameters
         headers:headers
        progress:nil
         success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
            NSDictionary *data = [response[@"data"] isKindOfClass:[NSDictionary class]] ? response[@"data"] : nil;
            NSDictionary *contentListContainer = [data[@"content_list"] isKindOfClass:[NSDictionary class]] ? data[@"content_list"] : data;
            id collectCountObj = [data[@"collectCount"] respondsToSelector:@selector(integerValue)] ? data[@"collectCount"] : nil;
            if (![collectCountObj respondsToSelector:@selector(integerValue)]) {
                collectCountObj = [contentListContainer[@"collectCount"] respondsToSelector:@selector(integerValue)] ? contentListContainer[@"collectCount"] : nil;
            }
            if (![collectCountObj respondsToSelector:@selector(integerValue)]) {
                collectCountObj = [data[@"collect_count"] respondsToSelector:@selector(integerValue)] ? data[@"collect_count"] : nil;
            }
            if (![collectCountObj respondsToSelector:@selector(integerValue)]) {
                collectCountObj = [contentListContainer[@"collect_count"] respondsToSelector:@selector(integerValue)] ? contentListContainer[@"collect_count"] : nil;
            }
            self.lastMyContentCollectCount = [collectCountObj respondsToSelector:@selector(integerValue)] ? @([collectCountObj integerValue]) : nil;

            if (code == 200) {
                // 解析数据列表
                NSArray *listData = [contentListContainer[@"list"] isKindOfClass:[NSArray class]] ? contentListContainer[@"list"] : @[];
                NSMutableArray *contentList = [NSMutableArray array];

                for (NSDictionary *itemDict in listData) {
                    if ([itemDict isKindOfClass:[NSDictionary class]]) {
                        // 这里需要导入YALMyContentModel，但为了不破坏现有结构，我们先返回字典数组
                        // 在实际使用中，ViewController会将其转换为模型
                        [contentList addObject:itemDict];
                    }
                }
                if (completion) {
                    completion(YES, [contentList copy], msg, nil);
                }
            } else {
                self.lastMyContentCollectCount = nil;
                if (completion) {
                    NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                         code:code
                                                     userInfo:@{NSLocalizedDescriptionKey: msg}];
                    completion(NO, nil, msg, error);
                }
            }
        } else {
            self.lastMyContentCollectCount = nil;
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                     code:-1
                                                 userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
                completion(NO, nil, @"无效的响应格式", error);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        self.lastMyContentCollectCount = nil;
        if (completion) {
            completion(NO, nil, @"网络请求失败", error);
        }
    }];
}

- (void)getAllContentListWithPage:(NSInteger)page
                         pageSize:(NSInteger)pageSize
                       completion:(void (^)(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/list", YALAPIBaseURLString];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"page"] = @(MAX(page, 1));
    parameters[@"pageSize"] = @(MAX(pageSize, 1));
    parameters[@"size"] = @(MAX(pageSize, 1));
    parameters[@"limit"] = @(MAX(pageSize, 1));

    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network GET:url
      parameters:parameters
         headers:headers
        progress:nil
         success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
            if (completion) {
                completion(NO, nil, @"无效的响应格式", error);
            }
            return;
        }

        NSDictionary *response = (NSDictionary *)responseObject;
        NSInteger code = [response[@"code"] respondsToSelector:@selector(integerValue)] ? [response[@"code"] integerValue] : 200;
        NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
        id data = response[@"data"];
        NSArray *listData = nil;

        if ([data isKindOfClass:[NSDictionary class]]) {
            if ([data[@"list"] isKindOfClass:[NSArray class]]) {
                listData = data[@"list"];
            } else if ([data[@"records"] isKindOfClass:[NSArray class]]) {
                listData = data[@"records"];
            }
        } else if ([data isKindOfClass:[NSArray class]]) {
            listData = (NSArray *)data;
        } else if ([response[@"list"] isKindOfClass:[NSArray class]]) {
            listData = response[@"list"];
        }

        if (code != 200) {
            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:code
                                             userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"获取内容列表失败"}];
            if (completion) {
                completion(NO, nil, msg, error);
            }
            return;
        }

        NSMutableArray<YALPostModel *> *contentList = [NSMutableArray array];
        for (id item in listData) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSDictionary *itemDict = (NSDictionary *)item;
            if (!YALContentListShouldShowPublicContent(itemDict)) {
                continue;
            }
            YALPostModel *model = [[YALPostModel alloc] initWithDictionary:itemDict];
            [contentList addObject:model];
        }

        if (completion) {
            completion(YES, [contentList copy], msg, nil);
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, nil, @"网络请求失败", error);
        }
    }];
}

- (void)getMyCollectListWithCompletion:(void (^)(BOOL success, NSArray * _Nullable contentList, NSString * _Nullable message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/interact/collect/my", YALAPIBaseURLString];
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network GET:url
      parameters:nil
         headers:headers
        progress:nil
         success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        NSArray *rawList = nil;
        NSString *message = @"";

        if ([responseObject isKindOfClass:[NSArray class]]) {
            rawList = (NSArray *)responseObject;
        } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] respondsToSelector:@selector(integerValue)] ? [response[@"code"] integerValue] : 200;
            message = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
            if (code != 200) {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey: message.length > 0 ? message : @"获取我的收藏失败"}];
                if (completion) {
                    completion(NO, nil, message, error);
                }
                return;
            }

            id data = response[@"data"];
            if ([data isKindOfClass:[NSArray class]]) {
                rawList = (NSArray *)data;
            } else if ([data isKindOfClass:[NSDictionary class]]) {
                if ([data[@"list"] isKindOfClass:[NSArray class]]) {
                    rawList = data[@"list"];
                } else if ([data[@"records"] isKindOfClass:[NSArray class]]) {
                    rawList = data[@"records"];
                }
            } else if ([response[@"list"] isKindOfClass:[NSArray class]]) {
                rawList = response[@"list"];
            }
        }

        if (![rawList isKindOfClass:[NSArray class]]) {
            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
            if (completion) {
                completion(NO, nil, @"无效的响应格式", error);
            }
            return;
        }

        NSMutableArray<YALPostModel *> *contentList = [NSMutableArray array];
        for (id item in rawList) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }

            NSDictionary *itemDict = (NSDictionary *)item;
            NSDictionary *contentDict = [itemDict[@"content"] isKindOfClass:[NSDictionary class]] ? itemDict[@"content"] : nil;
            NSMutableDictionary *mergedDict = [NSMutableDictionary dictionary];

            // 兼容两种返回结构：
            // 1) 直接返回内容字段
            // 2) 返回收藏关系，真实内容放在 content 子字典里
            if ([contentDict isKindOfClass:[NSDictionary class]]) {
                [mergedDict addEntriesFromDictionary:contentDict];
                [mergedDict addEntriesFromDictionary:itemDict];
            } else {
                [mergedDict addEntriesFromDictionary:itemDict];
            }

            // 统一内容ID字段，避免出现 contentId/id 导致解析不到 content_id
            if (![mergedDict[@"content_id"] respondsToSelector:@selector(integerValue)]) {
                id contentId = mergedDict[@"contentId"];
                if (![contentId respondsToSelector:@selector(integerValue)]) {
                    contentId = mergedDict[@"id"];
                }
                if ([contentId respondsToSelector:@selector(integerValue)]) {
                    mergedDict[@"content_id"] = @([contentId integerValue]);
                }
            }

            YALPostModel *model = [[YALPostModel alloc] initWithDictionary:[mergedDict copy]];
            [contentList addObject:model];
        }

        if (completion) {
            completion(YES, [contentList copy], message, nil);
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, nil, @"网络请求失败", error);
        }
    }];
}

-(void)deleteContentWithId:(NSNumber *)contentId
                completion:(void (^)(BOOL success, NSString *message, NSError * _Nullable error))completion {
    YALNetworkManager *network = [YALNetworkManager shareManager];
    NSString *url = [NSString stringWithFormat:@"%@/content/delete?content_id=%@", YALAPIBaseURLString, contentId ?: @(0)];
    NSDictionary *parameters = nil;
    NSDictionary *headers = [[YALAuthManager sharedManager] getAuthHeadersWithToken];

    [network DELETE:url
         parameters:parameters
            headers:headers
            success:^(__unused NSURLSessionDataTask *task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSInteger code = [response[@"code"] integerValue];
            NSString *msg = [response[@"msg"] isKindOfClass:[NSString class]] ? response[@"msg"] : @"";
            if (code == 200) {
                if (completion) {
                    completion(YES, msg.length > 0 ? msg : @"删除成功", nil);
                }
            } else {
                NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey: msg.length > 0 ? msg : @"删除失败"}];
                if (completion) {
                    completion(NO, msg.length > 0 ? msg : @"删除失败", error);
                }
            }
        } else {
            NSError *error = [NSError errorWithDomain:@"YALContentManager"
                                                 code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"无效的响应格式"}];
            if (completion) {
                completion(NO, @"无效的响应格式", error);
            }
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, @"网络请求失败", error);
        }
    }];
}

@end
