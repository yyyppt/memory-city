//
//  YALPostModel.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALPostModel.h"
#import <float.h>
#import <math.h>

static BOOL YALPostModelBoolValue(id value, BOOL fallback) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [((NSNumber *)value) integerValue] != 0;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [((NSString *)value) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) {
            return fallback;
        }
        NSString *lower = [text lowercaseString];
        if ([lower isEqualToString:@"true"] || [lower isEqualToString:@"yes"] || [lower isEqualToString:@"公开"]) {
            return YES;
        }
        if ([lower isEqualToString:@"public"]) {
            return YES;
        }
        if ([lower isEqualToString:@"false"] || [lower isEqualToString:@"no"] || [lower isEqualToString:@"私密"]) {
            return NO;
        }
        if ([lower isEqualToString:@"private"] || [lower isEqualToString:@"仅自己可见"]) {
            return NO;
        }
        return text.integerValue != 0;
    }
    return fallback;
}

static BOOL YALPostModelResolvedPublicFlag(NSDictionary *dict) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    id value = dict[@"is_public"];
    if (!value || value == [NSNull null]) {
        value = dict[@"isPublic"];
    }
    if (!value || value == [NSNull null]) {
        return NO;
    }
    return YALPostModelBoolValue(value, NO);
}

static double YALPostModelCoordinateValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [((NSNumber *)value) doubleValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [((NSString *)value) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return text.length > 0 ? text.doubleValue : 0.0;
    }
    return 0.0;
}

static NSString * _Nullable YALPostModelFirstString(NSDictionary *dict, NSArray<NSString *> *keys) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (text.length > 0) {
                return text;
            }
        }
    }
    return nil;
}

static NSNumber * _Nullable YALPostModelFirstNumber(NSDictionary *dict, NSArray<NSString *> *keys) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = dict[key];
        if ([value respondsToSelector:@selector(integerValue)]) {
            NSInteger integerValue = [value integerValue];
            if (integerValue > 0) {
                return @(integerValue);
            }
        }
    }
    return nil;
}

@implementation YALPostModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        // 解析内容ID
        if ([dict[@"content_id"] isKindOfClass:[NSNumber class]]) {
            self.contentId = dict[@"content_id"];
        } else if ([dict[@"content_id"] isKindOfClass:[NSString class]]) {
            self.contentId = @([dict[@"content_id"] integerValue]);
        }

        // 解析字符串类型字段
        self.title = [dict[@"title"] isKindOfClass:[NSString class]] ? dict[@"title"] : @"";
        self.content = [dict[@"content"] isKindOfClass:[NSString class]] ? dict[@"content"] : @"";
        self.desc = self.content; // 保持向后兼容
        self.city = [dict[@"city"] isKindOfClass:[NSString class]] ? dict[@"city"] : @"";
        self.year = [dict[@"year"] isKindOfClass:[NSString class]] ? dict[@"year"] : @"";
        self.mood = [dict[@"mood"] isKindOfClass:[NSString class]] ? dict[@"mood"] : @"";
        self.createTime = [dict[@"create_time"] isKindOfClass:[NSString class]] ? dict[@"create_time"] : @"";
        if (self.createTime.length == 0 && [dict[@"created_at"] isKindOfClass:[NSString class]]) {
            self.createTime = dict[@"created_at"];
        }
        self.locationName = [dict[@"location_name"] isKindOfClass:[NSString class]] ? dict[@"location_name"] : @"";
        self.latitude = YALPostModelCoordinateValue(dict[@"latitude"]);
        if (fabs(self.latitude) < DBL_EPSILON) {
            self.latitude = YALPostModelCoordinateValue(dict[@"lat"]);
        }
        self.longitude = YALPostModelCoordinateValue(dict[@"longitude"]);
        if (fabs(self.longitude) < DBL_EPSILON) {
            self.longitude = YALPostModelCoordinateValue(dict[@"lng"]);
        }
        if (fabs(self.longitude) < DBL_EPSILON) {
            self.longitude = YALPostModelCoordinateValue(dict[@"lon"]);
        }
        id likeCountValue = dict[@"like_count"];
        if ([likeCountValue respondsToSelector:@selector(integerValue)]) {
            self.likeCount = MAX([likeCountValue integerValue], 0);
        }
        id collectCountValue = dict[@"collect_count"];
        if (![collectCountValue respondsToSelector:@selector(integerValue)]) {
            collectCountValue = dict[@"favorite_count"];
        }
        if (![collectCountValue respondsToSelector:@selector(integerValue)]) {
            collectCountValue = dict[@"collected_count"];
        }
        if (![collectCountValue respondsToSelector:@selector(integerValue)]) {
            collectCountValue = dict[@"collectCount"];
        }
        if (![collectCountValue respondsToSelector:@selector(integerValue)]) {
            collectCountValue = dict[@"favoriteCount"];
        }
        if ([collectCountValue respondsToSelector:@selector(integerValue)]) {
            self.collectCount = MAX([collectCountValue integerValue], 0);
        }
        id commentCountValue = dict[@"comment_count"];
        if ([commentCountValue respondsToSelector:@selector(integerValue)]) {
            self.commentCount = MAX([commentCountValue integerValue], 0);
        }
        id likedValue = dict[@"is_liked"];
        if (![likedValue respondsToSelector:@selector(boolValue)]) {
            likedValue = dict[@"is_likeed"];
        }
        if (![likedValue respondsToSelector:@selector(boolValue)]) {
            likedValue = dict[@"is_like"];
        }
        if (![likedValue respondsToSelector:@selector(boolValue)]) {
            likedValue = dict[@"liked"];
        }
        if ([likedValue respondsToSelector:@selector(boolValue)]) {
            self.isLiked = YALPostModelBoolValue(likedValue, NO);
        }
        id collectedValue = dict[@"is_collected"];
        if (![collectedValue respondsToSelector:@selector(boolValue)]) {
            collectedValue = dict[@"is_collect"];
        }
        if (![collectedValue respondsToSelector:@selector(boolValue)]) {
            collectedValue = dict[@"collect_status"];
        }
        if (![collectedValue respondsToSelector:@selector(boolValue)]) {
            collectedValue = dict[@"collected"];
        }
        if ([collectedValue respondsToSelector:@selector(boolValue)]) {
            self.isCollected = YALPostModelBoolValue(collectedValue, NO);
        }

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
        self.authorUserId = YALPostModelFirstNumber(dict, @[@"user_id", @"author_id", @"publisher_id", @"uid", @"userid"]);
        if (!self.authorUserId) {
            self.authorUserId = YALPostModelFirstNumber(authorInfo, @[@"user_id", @"author_id", @"id", @"uid", @"userid"]);
        }
        self.authorNickname = YALPostModelFirstString(dict, @[@"user_nickname", @"nickname", @"author_name", @"publisher_name", @"user_name", @"username"]);
        if (self.authorNickname.length == 0) {
            self.authorNickname = YALPostModelFirstString(authorInfo, @[@"nickname", @"user_nickname", @"name", @"author_name", @"user_name", @"username"]);
        }
        self.authorAvatar = YALPostModelFirstString(dict, @[@"user_avatar", @"avatar", @"avatar_url", @"author_avatar"]);
        if (self.authorAvatar.length == 0) {
            self.authorAvatar = YALPostModelFirstString(authorInfo, @[@"avatar", @"avatar_url", @"user_avatar", @"author_avatar"]);
        }
        self.authorBio = YALPostModelFirstString(dict, @[@"user_bio", @"bio", @"author_bio"]);
        if (self.authorBio.length == 0) {
            self.authorBio = YALPostModelFirstString(authorInfo, @[@"bio", @"user_bio", @"signature", @"intro"]);
        }
        self.isPublic = YALPostModelResolvedPublicFlag(dict);

        // 解析图片数组 - 尝试多种可能的字段名
        NSArray *imageArray = nil;

        // 尝试小写 images
        if ([dict[@"images"] isKindOfClass:[NSArray class]]) {
            imageArray = dict[@"images"];
        }
        // 尝试大写 Images（兼容旧代码）
        else if ([dict[@"Images"] isKindOfClass:[NSArray class]]) {
            imageArray = dict[@"Images"];
        }
        // 尝试 image_urls
        else if ([dict[@"image_urls"] isKindOfClass:[NSArray class]]) {
            imageArray = dict[@"image_urls"];
        }

        if (imageArray) {
            NSMutableArray *imageUrls = [NSMutableArray array];
            for (id imageObj in imageArray) {
                if ([imageObj isKindOfClass:[NSString class]]) {
                    NSString *urlString = (NSString *)imageObj;
                    // 确保URL是有效的
                    if (urlString.length > 0) {
                        // 如果URL没有协议头，添加http://
                        if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"]) {
                            urlString = [NSString stringWithFormat:@"http://%@", urlString];
                        }
                        [imageUrls addObject:urlString];
                    }
                }
            }
            self.images = [imageUrls copy];
            self.imageURLString = imageUrls.firstObject ?: @""; // 保持向后兼容
        } else {
            self.images = @[];
            self.imageURLString = @"";
        }

        // 🔥 关键修复：如果没有图片URL，使用模拟图片
        if (self.imageURLString.length == 0) {
            // 使用Lorem Picsum随机图片（稳定的图片服务）
            // 根据内容ID生成不同的图片，确保同一内容显示相同图片
            NSInteger picId = [self.contentId integerValue] % 100 + 1;
            self.imageURLString = [NSString stringWithFormat:@"https://picsum.photos/300/400?image=%ld", (long)picId];
        }

        // 设置默认图片
        if (@available(iOS 13.0, *)) {
            self.image = [UIImage systemImageNamed:@"photo"];
        } else {
            self.image = [UIImage imageNamed:@"placeholder"];
        }

        // 设置合理的图片尺寸（模拟图片是300x400）
        self.imageWidth = 300.0;
        self.imageHeight = 400.0;

    }
    return self;
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<YALPostModel: %p> contentId: %@, title: %@, city: %@, year: %@, mood: %@, images: %@, imageURLString: %@",
            self, self.contentId, self.title, self.city, self.year, self.mood, self.images, self.imageURLString];
}

@end
