//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//
#import "YALMineProfileModel.h"

@implementation YALMineProfileModel

- (instancetype)initWithName:(NSString *)name
                         bio:(NSString *)bio
              publishedCount:(NSString *)publishedCount
                 memoryCount:(NSString *)memoryCount
                  trackCount:(NSString *)trackCount {
    self = [super init];
    if (self) {
        _name = [name copy];
        _bio = [bio copy];
        _publishedCount = [publishedCount copy];
        _memoryCount = [memoryCount copy];
        _trackCount = [trackCount copy];
    }
    return self;
}

+ (NSArray<YALMineProfileModel *> *)defaultProfiles {
    return @[
        [[YALMineProfileModel alloc] initWithName:@"老街漫游者"
                                              bio:@"把旧巷、地图和日常瞬间，慢慢收进 MemoryCity。"
                                   publishedCount:@"24"
                                      memoryCount:@"86"
                                       trackCount:@"12"],
        [[YALMineProfileModel alloc] initWithName:@"巷口记录官"
                                              bio:@"每次路过，都想给城市留一张有温度的照片。"
                                   publishedCount:@"31"
                                      memoryCount:@"104"
                                       trackCount:@"19"],
        [[YALMineProfileModel alloc] initWithName:@"夜色收藏家"
                                              bio:@"偏爱傍晚光影，也偏爱有故事的旧街区。"
                                   publishedCount:@"17"
                                      memoryCount:@"73"
                                       trackCount:@"9"]
    ];
}

@end
