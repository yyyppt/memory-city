//
//  YALPostModel.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALPostModel : NSObject

// 图片相关
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *imageURLString;
@property (nonatomic, assign) CGFloat imageWidth;
@property (nonatomic, assign) CGFloat imageHeight;

// 内容信息
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;

// 新增字段 - 与后端接口对应
@property (nonatomic, strong) NSNumber *contentId;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *year;
@property (nonatomic, copy) NSString *mood;
@property (nonatomic, strong) NSArray<NSString *> *images;
@property (nonatomic, copy) NSString *createTime;
@property (nonatomic, assign) BOOL isPublic;

/// 从字典初始化模型
/// @param dict 字典数据
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
