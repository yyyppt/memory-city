//
//  YALHomeController.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALMineSettingsController : UIViewController

@property (nonatomic, copy, nullable) void (^tapShuffleProfileBlock)(void);
@property (nonatomic, copy, nullable) void (^tapShareBlock)(void);
@property (nonatomic, copy, nullable) void (^tapClearBadgeBlock)(void);
@property (nonatomic, copy, nullable) void (^tapLogoutBlock)(void);

@end

NS_ASSUME_NONNULL_END
