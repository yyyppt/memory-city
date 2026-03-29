//
//  YALMyContentModel.h
//  MemoryCity
//
//  Created by AI Assistant on 2026/3/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 我的内容列表模型
@interface YALMyContentModel : NSObject

/// 内容ID
@property (nonatomic, strong) NSNumber *contentId;
/// 标题
@property (nonatomic, copy) NSString *title;
/// 内容正文
@property (nonatomic, copy) NSString *content;
/// 城市
@property (nonatomic, copy) NSString *city;
/// 年份
@property (nonatomic, copy) NSString *year;
/// 心情标签
@property (nonatomic, copy) NSString *mood;
/// 图片URL数组
@property (nonatomic, strong) NSArray<NSString *> *images;
/// 创建时间
@property (nonatomic, copy) NSString *createTime;

/// 从字典初始化模型
/// @param dict 字典数据
- (instancetype)initWithDictionary:(NSDictionary *)dict;

/// 将模型数组转换为字典数组
+ (NSArray<NSDictionary *> *)dictionaryArrayFromModels:(NSArray<YALMyContentModel *> *)models;

@end

NS_ASSUME_NONNULL_END