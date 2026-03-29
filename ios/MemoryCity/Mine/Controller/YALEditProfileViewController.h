//
//  YALEditProfileViewController.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YALAuthUserModel;

@interface YALEditProfileViewController : UIViewController

/// 初始化方法，传入当前用户信息
- (instancetype)initWithUser:(YALAuthUserModel *)user;

/// 编辑完成回调
@property (nonatomic, copy) void (^onEditComplete)(NSString * _Nullable newNickname, NSString * _Nullable newAvatar);

@end

NS_ASSUME_NONNULL_END
