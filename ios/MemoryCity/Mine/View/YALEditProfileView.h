//
//  YALEditProfileView.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YALEditProfileView;
@class YALAuthUserModel;

@protocol YALEditProfileViewDelegate <NSObject>

/// 头像选择按钮点击
- (void)editProfileViewDidTapAvatar:(YALEditProfileView *)view;

/// 保存按钮点击
- (void)editProfileViewDidTapSave:(YALEditProfileView *)view;

/// 取消按钮点击
- (void)editProfileViewDidTapCancel:(YALEditProfileView *)view;

@end

@interface YALEditProfileView : UIView

@property (nonatomic, weak) id<YALEditProfileViewDelegate> delegate;

/// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame;

/// 应用用户数据
- (void)applyUser:(YALAuthUserModel *)user;

/// 获取当前编辑的数据
- (NSDictionary *)getEditedData;

/// 设置头像图片
- (void)setAvatarImage:(UIImage *)image;

/// 显示错误消息
- (void)showErrorMessage:(NSString *)message forField:(NSString *)field;

/// 清除错误消息
- (void)clearErrorMessageForField:(NSString *)field;

@end

NS_ASSUME_NONNULL_END