//
//  YALPostModel.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALPostModel.h"

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
        id publicValue = dict[@"is_public"];
        if ([publicValue respondsToSelector:@selector(boolValue)]) {
            self.isPublic = [publicValue boolValue];
        } else {
            // 接口未返回隐私字段时，首页默认按公开内容处理。
            self.isPublic = YES;
        }

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
            NSLog(@"🖼️ 内容ID %@ 使用模拟图片URL: %@", self.contentId, self.imageURLString);
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

        NSLog(@"📸 最终图片配置 - URL: %@, 尺寸: %.0fx%.0f",
              self.imageURLString, self.imageWidth, self.imageHeight);
    }
    return self;
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<YALPostModel: %p> contentId: %@, title: %@, city: %@, year: %@, mood: %@, images: %@, imageURLString: %@",
            self, self.contentId, self.title, self.city, self.year, self.mood, self.images, self.imageURLString];
}

@end
