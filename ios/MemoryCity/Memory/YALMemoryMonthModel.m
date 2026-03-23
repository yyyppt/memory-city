#import "YALMemoryMonthModel.h"

@implementation YALMemoryMonthModel

- (NSString *)monthName {
    static NSArray<NSString *> *names;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = @[@"January", @"February", @"March", @"April", @"May", @"June",
                  @"July", @"August", @"September", @"October", @"November", @"December"];
    });
    NSInteger idx = MAX(1, MIN(12, self.month)) - 1;
    return names[idx];
}

- (NSString *)monthNumberText {
    return [NSString stringWithFormat:@"%02ld", (long)MAX(1, MIN(12, self.month))];
}

@end

