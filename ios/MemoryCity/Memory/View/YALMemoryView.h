#import <UIKit/UIKit.h>
#import "YALMemoryMonthModel.h"

NS_ASSUME_NONNULL_BEGIN

@class YALMemoryView;

@protocol YALMemoryViewDelegate <NSObject>
@optional
- (void)memoryViewDidTapPrevYear:(YALMemoryView *)view;
- (void)memoryViewDidTapNextYear:(YALMemoryView *)view;
- (void)memoryView:(YALMemoryView *)view didSelectMonth:(YALMemoryMonthModel *)month;
- (void)memoryViewDidTapYear:(YALMemoryView *)view;
@end

@interface YALMemoryView : UIView

@property (nonatomic, weak, nullable) id<YALMemoryViewDelegate> delegate;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, strong) NSArray<YALMemoryMonthModel *> *months;

/// 有发布内容的年份（可点年份、左右箭头仅在这些年间切换）
@property (nonatomic, copy) NSSet<NSNumber *> *yearsWithContent;
/// 展示区间：最早发布年 ～ 今年（用于年份折叠列表）
@property (nonatomic, assign) NSInteger rangeFirstYear;
@property (nonatomic, assign) NSInteger rangeLastYear;

- (void)reload;
/// 根据 year / yearsWithContent 更新年份颜色、可点、箭头可用
- (void)reloadYearNavigation;

@end

NS_ASSUME_NONNULL_END

