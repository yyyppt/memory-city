//
//  YALMemoryPoint.h
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class YALPostModel;

NS_ASSUME_NONNULL_BEGIN

@interface YALMemoryPoint : MKPointAnnotation

@property (nonatomic, copy) NSString *memoryID;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, assign) BOOL userCreated;
@property (nonatomic, strong, nullable) YALPostModel *postModel;

+ (instancetype)pointWithCoordinate:(CLLocationCoordinate2D)coordinate
                              title:(NSString *)title
                           subtitle:(NSString *)subtitle
                         detailText:(NSString *)detailText
                        userCreated:(BOOL)userCreated;

@end

NS_ASSUME_NONNULL_END
