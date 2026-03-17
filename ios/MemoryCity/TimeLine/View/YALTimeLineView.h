#import <UIKit/UIKit.h>
#import "YALTimeLineSectionModel.h"
#import "YALTimeLineEntryModel.h"

NS_ASSUME_NONNULL_BEGIN

@class YALTimeLineView;

@protocol YALTimeLineViewDelegate <NSObject>

@optional
- (void)timeLineView:(YALTimeLineView *)view didToggleSectionAtIndex:(NSInteger)sectionIndex;
- (void)timeLineView:(YALTimeLineView *)view didSelectEntry:(YALTimeLineEntryModel *)entry;

@end

@interface YALTimeLineView : UIView

@property (nonatomic, weak, nullable) id<YALTimeLineViewDelegate> delegate;
@property (nonatomic, strong) NSArray<YALTimeLineSectionModel *> *sections;

- (void)reloadData;
- (void)reloadDataAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
