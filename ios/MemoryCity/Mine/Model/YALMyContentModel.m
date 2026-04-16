//
//  YALMyContentModel.m
//  MemoryCity
//
//  Created by AI Assistant on 2026/3/30.
//

#import "YALMyContentModel.h"

@implementation YALMyContentModel

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
        self.city = [dict[@"city"] isKindOfClass:[NSString class]] ? dict[@"city"] : @"";
        self.year = [dict[@"year"] isKindOfClass:[NSString class]] ? dict[@"year"] : @"";
        self.mood = [dict[@"mood"] isKindOfClass:[NSString class]] ? dict[@"mood"] : @"";
        self.createTime = [dict[@"create_time"] isKindOfClass:[NSString class]] ? dict[@"create_time"] : @"";
        
        // 解析图片数组
        if ([dict[@"images"] isKindOfClass:[NSArray class]]) {
            NSMutableArray *imageUrls = [NSMutableArray array];
            for (id imageObj in dict[@"images"]) {
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
        } else {
            self.images = @[];
        }

        // 🔥 关键修复：如果没有图片，使用模拟图片
        if (self.images.count == 0 && self.contentId) {
            // 使用Lorem Picsum随机图片
            NSInteger picId = [self.contentId integerValue] % 100 + 1;
            NSString *imageUrl = [NSString stringWithFormat:@"https://picsum.photos/300/400?image=%ld", (long)picId];
            self.images = @[imageUrl];
        }
    }
    return self;
}

+ (NSArray<NSDictionary *> *)dictionaryArrayFromModels:(NSArray<YALMyContentModel *> *)models {
    NSMutableArray *dictArray = [NSMutableArray array];
    for (YALMyContentModel *model in models) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        if (model.contentId) {
            dict[@"content_id"] = model.contentId;
        }
        
        if (model.title) {
            dict[@"title"] = model.title;
        }
        
        if (model.content) {
            dict[@"content"] = model.content;
        }
        
        if (model.city) {
            dict[@"city"] = model.city;
        }
        
        if (model.year) {
            dict[@"year"] = model.year;
        }
        
        if (model.mood) {
            dict[@"mood"] = model.mood;
        }
        
        if (model.images) {
            dict[@"images"] = model.images;
        }
        
        if (model.createTime) {
            dict[@"create_time"] = model.createTime;
        }
        
        [dictArray addObject:[dict copy]];
    }
    return [dictArray copy];
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<YALMyContentModel: %p> contentId: %@, title: %@, city: %@, year: %@, mood: %@, images: %@, createTime: %@",
            self, self.contentId, self.title, self.city, self.year, self.mood, self.images, self.createTime];
}

@end
