//
//  YALPostDetailController.h
//  MemoryCity
//
//  Created by mac on 2026/3/17.
//

#import <UIKit/UIKit.h>

@class YALPostModel;

NS_ASSUME_NONNULL_BEGIN

@interface YALPostDetailController : UIViewController

@property (nonatomic, strong) YALPostModel *post;
@property (nonatomic, assign) BOOL openedFromAuthorProfile;

@end

NS_ASSUME_NONNULL_END
