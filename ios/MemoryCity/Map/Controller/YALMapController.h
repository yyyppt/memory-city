//
//  YALMapController.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^YALMapLocationSelectionHandler)(CLLocationCoordinate2D coordinate, NSString *locationName);

@interface YALMapController : UIViewController

@property (nonatomic, assign) BOOL selectionMode;
@property (nonatomic, assign) BOOL playsFootprintAnimationOnAppear;
@property (nonatomic, copy, nullable) YALMapLocationSelectionHandler onLocationSelected;

@end

NS_ASSUME_NONNULL_END
