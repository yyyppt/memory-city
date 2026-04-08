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

@implementation YALSearchContentModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _contentId = YALSearchNumberValue(dict[@"content_id"]);
        _title = YALSearchTrimmedString(dict[@"title"]);
        _content = YALSearchTrimmedString(dict[@"content"]);
        _city = YALSearchTrimmedString(dict[@"city"]);
        _year = YALSearchTrimmedString(dict[@"year"]);
        _mood = YALSearchTrimmedString(dict[@"mood"]);
        _createdAt = YALSearchTrimmedString(dict[@"created_at"]);

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
