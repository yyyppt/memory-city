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

@implementation YALSearchContentModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
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

        _contentId = YALSearchNumberValue(dict[@"content_id"]);
        _userId = YALSearchFirstNumber(dict, @[@"user_id", @"author_id", @"publisher_id", @"uid", @"userid"]);
        if (_userId == nil) {
            _userId = YALSearchFirstNumber(authorInfo, @[@"user_id", @"author_id", @"id", @"uid", @"userid"]);
        }
        _title = YALSearchTrimmedString(dict[@"title"]);
        _content = YALSearchTrimmedString(dict[@"content"]);
        _city = YALSearchTrimmedString(dict[@"city"]);
        _year = YALSearchTrimmedString(dict[@"year"]);
        _mood = YALSearchTrimmedString(dict[@"mood"]);
        _createdAt = YALSearchTrimmedString(dict[@"created_at"]);
        _authorNickname = YALSearchFirstString(dict, @[@"user_nickname", @"nickname", @"author_name", @"publisher_name", @"name"]);
        if (_authorNickname.length == 0) {
            _authorNickname = YALSearchFirstString(authorInfo, @[@"nickname", @"user_nickname", @"name", @"author_name"]);
        }
        _authorUsername = YALSearchFirstString(dict, @[@"username", @"user_name", @"account"]);
        if (_authorUsername.length == 0) {
            _authorUsername = YALSearchFirstString(authorInfo, @[@"username", @"user_name", @"account"]);
        }
        _authorAvatar = YALSearchFirstString(dict, @[@"user_avatar", @"avatar", @"avatar_url", @"author_avatar"]);
        if (_authorAvatar.length == 0) {
            _authorAvatar = YALSearchFirstString(authorInfo, @[@"avatar", @"avatar_url", @"user_avatar", @"author_avatar"]);
        }
        _authorBio = YALSearchFirstString(dict, @[@"user_bio", @"bio", @"author_bio", @"signature", @"intro"]);
        if (_authorBio.length == 0) {
            _authorBio = YALSearchFirstString(authorInfo, @[@"bio", @"user_bio", @"author_bio", @"signature", @"intro"]);
        }

        NSNumber *likeCount = YALSearchNumberValue(dict[@"like_count"]);
        _likeCount = MAX(likeCount.integerValue, 0);

        NSNumber *commentCount = YALSearchNumberValue(dict[@"comment_count"]);
        _commentCount = MAX(commentCount.integerValue, 0);

        NSArray *rawImages = nil;
        if ([dict[@"Images"] isKindOfClass:[NSArray class]]) {
            rawImages = dict[@"Images"];
        } else if ([dict[@"images"] isKindOfClass:[NSArray class]]) {
            rawImages = dict[@"images"];
        } else if ([dict[@"image_urls"] isKindOfClass:[NSArray class]]) {
            rawImages = dict[@"image_urls"];
        }

        NSMutableArray<NSString *> *normalizedImages = [NSMutableArray array];
        for (id item in rawImages) {
            NSString *url = YALSearchTrimmedString(item);
            if (url.length > 0) {
                [normalizedImages addObject:url];
            }
        }
        _images = [normalizedImages copy];
    }
    return self;
}

@end
