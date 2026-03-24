//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALMineProfileModel : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bio;
@property (nonatomic, copy) NSString *publishedCount;
@property (nonatomic, copy) NSString *memoryCount;
@property (nonatomic, copy) NSString *trackCount;

- (instancetype)initWithName:(NSString *)name
                         bio:(NSString *)bio
              publishedCount:(NSString *)publishedCount
                 memoryCount:(NSString *)memoryCount
                  trackCount:(NSString *)trackCount;

+ (NSArray<YALMineProfileModel *> *)defaultProfiles;

@end

NS_ASSUME_NONNULL_END
