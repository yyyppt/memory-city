#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALMemoryMonthModel : NSObject

@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month; // 1~12
@property (nonatomic, assign) NSInteger memoryCount;
@property (nonatomic, copy) NSString *featuredTitle;
@property (nonatomic, strong, nullable) UIImage *coverImage;
/// 封面图片 URL（来自接口 images[0]，用于 SDWebImage 异步加载）
@property (nonatomic, copy, nullable) NSString *coverImageURLString;
@property (nonatomic, copy) NSArray<NSString *> *coverImageURLStrings;

@property (nonatomic, readonly) NSString *monthName;
@property (nonatomic, readonly) NSString *monthNumberText;

@end

NS_ASSUME_NONNULL_END
