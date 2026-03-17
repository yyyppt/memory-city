#import "YALMemoryPoint.h"

@implementation YALMemoryPoint

+ (instancetype)pointWithCoordinate:(CLLocationCoordinate2D)coordinate
                              title:(NSString *)title
                           subtitle:(NSString *)subtitle
                         detailText:(NSString *)detailText
                        userCreated:(BOOL)userCreated {
    YALMemoryPoint *point = [[YALMemoryPoint alloc] init];
    point.coordinate = coordinate;
    point.title = title;
    point.subtitle = subtitle;
    point.detailText = detailText;
    point.userCreated = userCreated;
    point.memoryID = [[NSUUID UUID] UUIDString];
    return point;
}

@end
