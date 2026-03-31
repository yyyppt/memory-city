//
//  YALTimeLineEntryModel.h
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALTimeLineEntryModel : NSObject

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *subtitleText; // 内容预览（可用于展示content前几行）
@property (nonatomic, copy) NSString *dateText;

/// 详情里要展示的正文内容
@property (nonatomic, copy) NSString *contentText;

/// 图片 URL 数组（用于 SDWebImage 异步加载）
@property (nonatomic, copy) NSArray<NSString *> *imageURLStrings;

/// 兼容旧 demo：直接持有UIImage
@property (nonatomic, strong, nullable) UIImage *image;

- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         date:(NSString *)date
                        image:(nullable UIImage *)image;

/// 真实数据构造（推荐）
- (instancetype)initWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                         date:(NSString *)date
                      content:(nullable NSString *)content
                   imageURLs:(nullable NSArray<NSString *> *)imageURLs;

@end

NS_ASSUME_NONNULL_END
