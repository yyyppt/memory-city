//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//
#import <UIKit/UIKit.h>
#import "YALMineProfileModel.h"

NS_ASSUME_NONNULL_BEGIN

@class YALMineView;
@class YALAuthUserModel;

@protocol YALMineViewDelegate <NSObject>
@optional
- (void)mineViewDidTapEditProfile:(YALMineView *)view;
- (void)mineViewDidTapLogin:(YALMineView *)view;
- (void)mineView:(YALMineView *)view didTapStatAtIndex:(NSInteger)index;
- (void)mineView:(YALMineView *)view didTapPersonalItemAtIndex:(NSInteger)index;
@end

@interface YALMineView : UIView

@property (nonatomic, weak, nullable) id<YALMineViewDelegate> delegate;

- (void)applyProfile:(YALMineProfileModel *)profile;
- (void)applyAuthUser:(YALAuthUserModel *)user;
- (void)setGuestLoginModeEnabled:(BOOL)enabled;
- (void)updateCreatorStatsWithPublicCount:(nullable NSNumber *)publicCount
                              privateCount:(nullable NSNumber *)privateCount;

@end

NS_ASSUME_NONNULL_END
