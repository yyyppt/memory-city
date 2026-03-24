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

@protocol YALMineViewDelegate <NSObject>
@optional
- (void)mineViewDidTapEditProfile:(YALMineView *)view;
- (void)mineView:(YALMineView *)view didTapQuickActionAtIndex:(NSInteger)index;
- (void)mineView:(YALMineView *)view didTapServiceAtIndex:(NSInteger)index;
@end

@interface YALMineView : UIView

@property (nonatomic, weak, nullable) id<YALMineViewDelegate> delegate;

- (void)applyProfile:(YALMineProfileModel *)profile;

@end

NS_ASSUME_NONNULL_END
