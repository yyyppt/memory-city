//
//  YALReleaseController.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALReleaseController : UIViewController

/// 编辑/重新发布模式：预填封面与文字
- (instancetype)initWithEditCoverImage:(nullable UIImage *)coverImage
                              dateText:(nullable NSString *)dateText
                                  body:(nullable NSString *)body;

@end

NS_ASSUME_NONNULL_END
