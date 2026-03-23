#import <UIKit/UIKit.h>
#import "YALTimeLineEntryModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YALTimeLineDayCell : UITableViewCell

- (void)configureWithEntry:(YALTimeLineEntryModel *)entry dayText:(NSString *)dayText weekdayText:(NSString *)weekdayText;

@end

NS_ASSUME_NONNULL_END
