//
//  YALTimeLineController.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALTimeLineController : UIViewController

@property (nonatomic, assign) NSInteger displayYear;  // 0 means auto/demo
@property (nonatomic, assign) NSInteger displayMonth; // 1~12, 0 means all/demo

@end

NS_ASSUME_NONNULL_END
