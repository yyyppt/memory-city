//
//  YALReleaseController.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALReleaseController : UIViewController

@property (nonatomic, assign) CLLocationCoordinate2D presetCoordinate;
@property (nonatomic, assign) BOOL hasPresetCoordinate;
@property (nonatomic, copy, nullable) NSString *presetLocationName;

/// 编辑/重新发布模式：预填封面与文字
- (instancetype)initWithEditCoverImage:(nullable UIImage *)coverImage
                              dateText:(nullable NSString *)dateText
                                  body:(nullable NSString *)body;

/// 编辑/重新发布模式：预填封面、标题、文字（旧构造保持兼容）
- (instancetype)initWithEditCoverImage:(nullable UIImage *)coverImage
                                 title:(nullable NSString *)title
                              dateText:(nullable NSString *)dateText
                                  body:(nullable NSString *)body;

@end

NS_ASSUME_NONNULL_END
