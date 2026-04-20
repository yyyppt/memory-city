//
//  YALSearchContentModel.m
//  MemoryCity
//
//  Created by Codex on 2026/4/8.
//

#import "YALSearchContentModel.h"

static NSString *YALSearchTrimmedString(id value) {
    if (![value isKindOfClass:[NSString class]]) {
        return @"";
    }
    return [((NSString *)value) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSNumber * _Nullable YALSearchNumberValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = YALSearchTrimmedString(value);
        if (text.length > 0) {
            return @([text integerValue]);
        }
    }
    return nil;
}

static NSString *YALSearchFirstString(NSDictionary *dict, NSArray<NSString *> *keys) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    for (NSString *key in keys) {
        NSString *text = YALSearchTrimmedString(dict[key]);
        if (text.length > 0) {
            return text;
        }
    }
    return @"";
}

static NSDictionary * _Nullable YALSearchFirstNestedDictionary(NSDictionary *dict, NSArray<NSString *> *keys) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            return (NSDictionary *)value;
        }
    }
    return nil;
}

static NSNumber * _Nullable YALSearchFirstNumber(NSDictionary *dict, NSArray<NSString *> *keys) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        NSNumber *value = YALSearchNumberValue(dict[key]);
        if (value != nil) {
            return value;
        }
    }
    return nil;
}

static NSString *YALSearchFirstStringFromDictionaries(NSArray<NSDictionary *> *dicts, NSArray<NSString *> *keys) {
    for (NSDictionary *dict in dicts) {
        NSString *text = YALSearchFirstString(dict, keys);
        if (text.length > 0) {
            return text;
        }
    }
    return @"";
}

static NSNumber * _Nullable YALSearchFirstNumberFromDictionaries(NSArray<NSDictionary *> *dicts, NSArray<NSString *> *keys) {
    for (NSDictionary *dict in dicts) {
        NSNumber *value = YALSearchFirstNumber(dict, keys);
        if (value != nil) {
            return value;
        }
    }
    return nil;
}

static NSArray<NSString *> *YALSearchNormalizedImagesFromValue(id value) {
    NSMutableArray<NSString *> *normalizedImages = [NSMutableArray array];
    if ([value isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)value) {
            if ([item isKindOfClass:[NSString class]]) {
                NSString *url = YALSearchTrimmedString(item);
                if (url.length > 0) {
                    [normalizedImages addObject:url];
                }
                continue;
            }

            if ([item isKindOfClass:[NSDictionary class]]) {
                NSString *url = YALSearchFirstString((NSDictionary *)item, @[@"url", @"image", @"image_url", @"src", @"path"]);
                if (url.length > 0) {
                    [normalizedImages addObject:url];
                }
            }
        }
    } else if ([value isKindOfClass:[NSString class]]) {
        NSString *url = YALSearchTrimmedString(value);
        if (url.length > 0) {
            [normalizedImages addObject:url];
        }
    }
    return [normalizedImages copy];
}

@implementation YALSearchContentModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        NSDictionary *contentInfo = YALSearchFirstNestedDictionary(dict, @[@"content", @"post", @"item", @"detail", @"data", @"content_info"]);
        NSDictionary *authorInfo = [dict[@"user"] isKindOfClass:[NSDictionary class]] ? dict[@"user"] : nil;
        if (!authorInfo) {
            authorInfo = [dict[@"author"] isKindOfClass:[NSDictionary class]] ? dict[@"author"] : nil;
        }
        if (!authorInfo) {
            authorInfo = [dict[@"publisher"] isKindOfClass:[NSDictionary class]] ? dict[@"publisher"] : nil;
        }
        if (!authorInfo) {
            authorInfo = [dict[@"user_info"] isKindOfClass:[NSDictionary class]] ? dict[@"user_info"] : nil;
        }
        if (!authorInfo && contentInfo != nil) {
            authorInfo = YALSearchFirstNestedDictionary(contentInfo, @[@"user", @"author", @"publisher", @"user_info"]);
        }

        NSArray<NSDictionary *> *contentSources = contentInfo != nil ? @[dict, contentInfo] : @[dict];
        NSArray<NSDictionary *> *authorSources = authorInfo != nil ? @[dict, contentInfo ?: @{}, authorInfo] : contentSources;

        _contentId = YALSearchFirstNumberFromDictionaries(contentSources, @[@"content_id", @"id", @"post_id", @"memory_id"]);
        _userId = YALSearchFirstNumberFromDictionaries(contentSources, @[@"user_id", @"author_id", @"publisher_id", @"uid", @"userid"]);
        if (_userId == nil && authorInfo != nil) {
            _userId = YALSearchFirstNumber(authorInfo, @[@"user_id", @"author_id", @"id", @"uid", @"userid"]);
        }
        _title = YALSearchFirstStringFromDictionaries(contentSources, @[@"title", @"name", @"subject"]);
        _content = YALSearchFirstStringFromDictionaries(contentSources, @[@"content", @"body", @"desc", @"description", @"text", @"detail", @"content_text", @"summary"]);
        _city = YALSearchFirstStringFromDictionaries(contentSources, @[@"city", @"location_city", @"locationName", @"location_name"]);
        _year = YALSearchFirstStringFromDictionaries(contentSources, @[@"year", @"publish_year", @"created_year"]);
        _mood = YALSearchFirstStringFromDictionaries(contentSources, @[@"mood", @"emotion", @"feeling"]);
        _createdAt = YALSearchFirstStringFromDictionaries(contentSources, @[@"created_at", @"create_time", @"createdAt", @"publish_time"]);
        _authorNickname = YALSearchFirstStringFromDictionaries(authorSources, @[@"user_nickname", @"nickname", @"author_name", @"publisher_name", @"name"]);
        _authorUsername = YALSearchFirstStringFromDictionaries(authorSources, @[@"username", @"user_name", @"account"]);
        _authorAvatar = YALSearchFirstStringFromDictionaries(authorSources, @[@"user_avatar", @"avatar", @"avatar_url", @"author_avatar"]);
        _authorBio = YALSearchFirstStringFromDictionaries(authorSources, @[@"user_bio", @"bio", @"author_bio", @"signature", @"intro", @"description"]);

        NSNumber *likeCount = YALSearchFirstNumberFromDictionaries(contentSources, @[@"like_count", @"likes_count", @"liked_count", @"likeCount"]);
        _likeCount = MAX(likeCount.integerValue, 0);

        NSNumber *commentCount = YALSearchFirstNumberFromDictionaries(contentSources, @[@"comment_count", @"comments_count", @"commentCount"]);
        _commentCount = MAX(commentCount.integerValue, 0);

        NSArray<NSString *> *images = @[];
        for (NSDictionary *source in contentSources) {
            NSArray<NSString *> *candidateImages = YALSearchNormalizedImagesFromValue(source[@"Images"]);
            if (candidateImages.count == 0) {
                candidateImages = YALSearchNormalizedImagesFromValue(source[@"images"]);
            }
            if (candidateImages.count == 0) {
                candidateImages = YALSearchNormalizedImagesFromValue(source[@"image_urls"]);
            }
            if (candidateImages.count == 0) {
                candidateImages = YALSearchNormalizedImagesFromValue(source[@"image"]);
            }
            if (candidateImages.count > 0) {
                images = candidateImages;
                break;
            }
        }
        _images = images;
    }
    return self;
}

@end
