//
//  YALPostModel.h
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YALPostModel : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGFloat imageWidth;
@property (nonatomic, assign) CGFloat imageHeight;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;

@end

NS_ASSUME_NONNULL_END

