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

- (void)reload;

@end

NS_ASSUME_NONNULL_END

