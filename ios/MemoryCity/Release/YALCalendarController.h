#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALCalendarController : UIViewController

@property (nonatomic, strong, nullable) NSDate *selectedDate;
@property (nonatomic, copy, nullable) void (^onDatePicked)(NSDate *date);

@end

NS_ASSUME_NONNULL_END

