//
//  YALTimeLineDetailController.h
//  MemoryCity
//
//  Created by mac on 2026/3/16.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YALTimeLineDetailController : ViewController

@property (nonatomic, copy) NSString *dateText;
@property (nonatomic, copy, nullable) NSString *titleText;
@property (nonatomic, copy, nullable) NSString *contentText;

/// 用于 SDWebImage 异步加载封面
@property (nonatomic, copy, nullable) NSString *coverImageURLString;

@property (nonatomic, strong, nullable) UIImage *coverImage;

@end

NS_ASSUME_NONNULL_END
